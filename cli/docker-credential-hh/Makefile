BINARY=docker-credential-hh
PREFIX=/usr/local/bin

all: build

build:
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o $(BINARY) ./...

install: build
	install -m 0755 $(BINARY) $(PREFIX)/$(BINARY)

clean:
	rm -f $(BINARY)
