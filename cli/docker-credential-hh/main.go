package main

import (
    "bytes"
    "encoding/json"
    "errors"
    "fmt"
    "io"
    "net/http"
    "os"
    "path/filepath"
    "strings"
)

type Config struct {
    PortalBase   string `json:"portal_base"`
    DownloadToken string `json:"download_token"`
    // Support additional field names for backwards compatibility
    EdgeAuth    string `json:"edge_auth"`
    LeaseURL    string `json:"lease_url"`
    BaseURL     string `json:"base_url"`
    URL         string `json:"url"`
    Token       string `json:"token"`
    Code        string `json:"code"`
}

func readStdin() (string, error) {
    b, err := io.ReadAll(os.Stdin)
    if err != nil {
        return "", err
    }
    return strings.TrimSpace(string(b)), nil
}

func getConfigPaths() []string {
    var paths []string

    // 1. Environment override
    if envConfig := os.Getenv("HH_CONFIG"); envConfig != "" {
        paths = append(paths, envConfig)
    }

    // 2. System config
    paths = append(paths, "/etc/hh/config.json")

    // 3. XDG config home
    if xdgConfig := os.Getenv("XDG_CONFIG_HOME"); xdgConfig != "" {
        paths = append(paths, filepath.Join(xdgConfig, "hh", "config.json"))
    }

    // 4. User home config
    if home := os.Getenv("HOME"); home != "" {
        paths = append(paths, filepath.Join(home, ".hh", "config.json"))
    }

    return paths
}

func loadConfig() (*Config, error) {
    paths := getConfigPaths()

    var lastErr error
    for _, p := range paths {
        f, err := os.Open(p)
        if err != nil {
            lastErr = err
            continue
        }
        defer f.Close()

        var c Config
        if err := json.NewDecoder(f).Decode(&c); err != nil {
            f.Close()
            lastErr = err
            continue
        }
        f.Close()

        // Normalize config fields - support multiple field names for backwards compatibility
        // Prefer the new field names first
        if c.LeaseURL != "" {
            c.PortalBase = c.LeaseURL
        } else if c.PortalBase == "" {
            if c.BaseURL != "" {
                c.PortalBase = c.BaseURL
            } else if c.URL != "" {
                c.PortalBase = c.URL
            }
        }

        // Keep EdgeAuth separate for X-Edge-Auth header
        // Set DownloadToken for X-Download-Token header (prioritize Token over legacy fields)
        if c.DownloadToken == "" {
            if c.Token != "" {
                c.DownloadToken = c.Token
            } else if c.Code != "" {
                c.DownloadToken = c.Code
            }
        }

        // Validate required fields
        if c.PortalBase == "" {
            lastErr = errors.New("missing portal_base/lease_url/base_url/url in config")
            continue
        }
        if c.DownloadToken == "" {
            lastErr = errors.New("missing download_token/token/code in config")
            continue
        }
        if c.EdgeAuth == "" {
            lastErr = errors.New("missing edge_auth in config")
            continue
        }

        return &c, nil
    }

    if lastErr != nil {
        return nil, fmt.Errorf("failed to load config from any path: %v", lastErr)
    }
    return nil, errors.New("no config files found")
}

func normalizeServer(s string) string {
    s = strings.TrimSpace(s)
    s = strings.TrimSuffix(s, "/v2/")
    s = strings.TrimSuffix(s, "/v2")
    s = strings.TrimSuffix(s, "/")
    if strings.HasPrefix(s, "https://") {
        s = strings.TrimPrefix(s, "https://")
    } else if strings.HasPrefix(s, "http://") {
        s = strings.TrimPrefix(s, "http://")
    }
    return s
}

func isGHCR(server string) bool {
    s := normalizeServer(server)
    return s == "ghcr.io" || strings.HasSuffix(s, ".ghcr.io")
}

func getLease(c *Config) (map[string]string, int, error) {
    // If PortalBase already contains /lease, use it directly, otherwise append /lease
    var url string
    if strings.HasSuffix(c.PortalBase, "/lease") {
        url = c.PortalBase
    } else {
        url = strings.TrimRight(c.PortalBase, "/") + "/lease"
    }

    req, err := http.NewRequest("POST", url, nil)
    if err != nil {
        return nil, 0, err
    }
    req.Header.Set("X-Edge-Auth", c.EdgeAuth)
    req.Header.Set("X-Download-Token", c.DownloadToken)
    client := &http.Client{}
    resp, err := client.Do(req)
    if err != nil {
        return nil, 0, err
    }
    defer resp.Body.Close()
    body, _ := io.ReadAll(resp.Body)
    if resp.StatusCode != 200 {
        return nil, resp.StatusCode, fmt.Errorf("lease failed: %s", strings.TrimSpace(string(body)))
    }
    var out map[string]string
    if err := json.NewDecoder(bytes.NewReader(body)).Decode(&out); err != nil {
        return nil, resp.StatusCode, err
    }
    return out, resp.StatusCode, nil
}

func debugf(format string, args ...interface{}) {
    if os.Getenv("HH_DEBUG") == "1" {
        fmt.Fprintf(os.Stderr, "debug: "+format+"\n", args...)
    }
}

func cmdGet() int {
    server, err := readStdin()
    if err != nil {
        debugf("failed to read stdin: %v", err)
        return 1
    }

    debugf("server input: %s", server)

    if !isGHCR(server) {
        debugf("not a GHCR server, exiting quietly")
        return 1
    }

    cfg, err := loadConfig()
    if err != nil {
        debugf("failed to load config: %v", err)
        return 1
    }

    debugf("loaded config with portal_base: %s", cfg.PortalBase)

    creds, status, err := getLease(cfg)
    if err != nil {
        debugf("lease failed with status %d: %v", status, err)
        // For authentication failures (401/403/404), exit quietly to allow anonymous fallback
        if status == 401 || status == 403 || status == 404 || status >= 400 {
            debugf("auth failure, allowing anonymous fallback")
            // Return exit 0 with no output to allow anonymous fallback
            return 0
        }
        // For other errors (network, etc.), provide minimal feedback
        debugf("network/other error during lease")
        // Return exit 0 with no output to allow anonymous fallback
        return 0
    }

    debugf("lease successful, returning credentials")

    // Only print JSON on success - this is what Docker/ORAS expects
    out := map[string]string{"ServerURL": creds["ServerURL"], "Username": creds["Username"], "Secret": creds["Secret"]}
    enc := json.NewEncoder(os.Stdout)
    enc.SetEscapeHTML(false)
    if err := enc.Encode(out); err != nil {
        return 1
    }
    return 0
}

func main() {
    if len(os.Args) < 2 {
        fmt.Fprintln(os.Stderr, "usage: docker-credential-hh <get|store|erase|list>")
        os.Exit(1)
    }
    cmd := os.Args[1]
    switch cmd {
    case "get":
        os.Exit(cmdGet())
    case "store", "erase":
        // no-op
        os.Exit(0)
    case "list":
        fmt.Println("{}")
        os.Exit(0)
    default:
        fmt.Fprintln(os.Stderr, "unknown command")
        os.Exit(1)
    }
}
