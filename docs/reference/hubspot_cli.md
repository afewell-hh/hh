Title: HubSpot CLI commands (v7.6.0) - HubSpot docs

URL Source: http://developers.hubspot.com/docs/developer-tooling/local-development/hubspot-cli/reference

Markdown Content:
Last modified: August 22, 2025

The HubSpot CLI connects your local development tools to HubSpot, allowing you to build and deploy [apps](https://developers.hubspot.com/docs/apps/developer-platform/build-apps/overview) to HubSpot, develop on the HubSpot CMS with version control, integrate with your favorite text editor, and more.Use this article as a reference for the available commands and formatting options for HubSpot’s local development tooling.If you haven’t installed the CLI yet, check out the [CLI installation guide](https://developers.hubspot.com/docs/developer-tooling/local-development/hubspot-cli/install-the-cli). Once you install the CLI and you’re ready to build your first app, check out the [quickstart guide](https://developers.hubspot.com/docs/getting-started/quickstart).

The current recommended version of the HubSpot CLI is `7.6.0` or later.

Show all commands
-----------------

Shows all commands and their definitions. To learn more about a specific command, add `--help` to the end of the command.

```
hs help
```

Install the CLI
---------------

You can install HubSpot local development tools either globally (recommended) or locally. To install the HubSpot tools globally, in your command line run the command below. To install locally, omit `-g` from the command.

```
npm install -g @hubspot/cli
```

To install the tools only in your current directory instead, run the command below. You do not need to install locally if you already have the CLI installed globally.

```
npm i @hubspot/cli@latest
```

Update the CLI
--------------

The CLI is updated regularly. To upgrade to the latest version of the local tools, run:

```
npm i -g @hubspot/cli@latest
```

Authentication
--------------

The following commands enable you to authenticate HubSpot accounts with the CLI so that you can interact with the account. If you haven’t yet authenticated an account with the CLI, you’ll first run `hs account auth` to create a centralized configuration file at the root of your working directory, `~/.hscli/config.yml`. This file will contain the authentication details for any connected HubSpot accounts. The rest of the commands will update that file.

### Initialize config and authentication

Creates a `config.yml` file at the root of your home directory (i.e., `~/.hscli/config.yml`), and sets up authentication for an account. If you’re adding authentication for a new account to an existing config file, run the [auth](http://developers.hubspot.com/docs/developer-tooling/local-development/hubspot-cli/reference#auth) command. When prompted for a name to use for the account, the name can’t contain spaces.

```
hs auth [flags]
```

**Flags**

| Flag | Description |
| --- | --- |
| `--account` | The specific account name to authenticate using the CLI. To get a full list of accounts, use the `hs accounts` command. |

### Migrate or merge your config files

Prior to version 7.4 of the CLI, configuration was stored within a `hubspot.config.yml` file, or multiple versions of this file if you were developing for multiple accounts. With the latest version of the CLI, one central config file, `~/.hscli/config.yml`, is used to manage all account configuration via the `hs account auth` command.If you have an existing `hubsport.config.yml` config file, you can migrate over to the new central config file by running the following command:

```
hs config migrate [--flags]
```

**Flags**

| Flag | Description |
| --- | --- |
| `--config` | Specify a path to an existing config file that should be used to migrate over to the new global config file. By default, the command will prompt you to migrate a deprecated config file in the current working directory to the new global config. |
| `--force` | By default, if conflicting values are detected between a deprecated config file and a global config file, you’ll be prompted to choose which value will be migrated over to your global config. You can bypass these prompts ahead of time by providing the `--force` flag. |

### Override the default account in your global config

If you want to override the default account in the `~/.hscli/config.yml` global config file, you can run the following command in any directory:

```
hs account create-override
```

The command will create an `.hsaccount` file in your current working directory. This file will list a single account from your global config that will act as youor default account for the current directory, along with any subsdirectories and files. If needed, you can use the `hs account remove-override` command to remove this file from your current working directory.

### hs init command

Creates a `hubspot.config.yml` file in the current directory and sets up authentication for an account. If you’re adding authentication for a new account to an existing config file, run the [auth](http://developers.hubspot.com/docs/developer-tooling/local-development/hubspot-cli/reference#auth) command. When prompted for a name to use for the account, the name can’t contain spaces.

```
hs init [flags]
```

**Flags**

| Flag | Description |
| --- | --- |
| `--auth-type` | The authentication protocol to use for authenticating your account. Supported values are `personalaccesskey` (default) and `oauth2`. |
| `--account` | The specific account name to authenticate using the CLI. To get a full list of accounts, use the `hs accounts` command. |

### Authenticate an account

Generate authentication for a HubSpot account using a [personal access key](https://developers.hubspot.com/docs/guides/cms/tools/personal-access-key). You can [generate your access key here](https://app.hubspot.com/login?loginRedirectUrl=https%3A%2F%2Fapp.hubspot.com%2Fshortlink%2Fpersonal-access-key%2F). If you already have a `hubspot.config.yml` file you can use this command to add credentials for additional accounts. When prompted for a name to use for the account, the name can’t contain spaces.

```
hs auth [flags]
```

**Flags**

| Flag | Description |
| --- | --- |
| `--auth-type` | The authentication protocol to use for authenticating your account. Supported values are `personalaccesskey` (default) and `oauth2`. |
| `--account` | The specific account name to authenticate using the CLI. To get a full list of accounts, use the `hs accounts` command. |

### List authenticated accounts

Lists the name, ID, and auth type for the each account in your config file. If you’re not seeing the accounts you expect, you may need to run the [auth](http://developers.hubspot.com/docs/developer-tooling/local-development/hubspot-cli/reference#auth) command to add accounts to your config file.

```
hs accounts list
```

### Set default account

Set the default account in your config file.

```
hs accounts use accountNameOrID
```

| Parameter | Description |
| --- | --- |
| `accountNameOrID` | Identify the new default account by its name (as set in the config file) or ID. |

### Remove an account

Removes an account from your config file.

```
hs accounts remove accountNameOrID
```

| Parameter | Description |
| --- | --- |
| `accountNameOrID` | Identify the account to remove by its name (as set in the config file) or ID. |

### Remove invalid accounts

Removes any deactivated HubSpot accounts from your config file.

```
hs accounts clean
```

Interacting with the developer file system
------------------------------------------

Using the CLI, you can interact with the [developer file system](https://developers.hubspot.com/docs/guides/cms/overview#developer-file-system), which is the file system in the [Design Manager](https://developers.hubspot.com/docs/guides/cms/tools/design-manager). These commands enable you to create new assets locally, such as modules and themes, upload them to the account, list files in the HubSpot account, or download existing files to your local environment.

### List files

List files stored in the developer file system by path or from the root. Works similar to using standard `ls` to view your current directory on your local machine.

```
hs ls [path]
hs list [path]
```

**Arguments**

| Argument | Description |
| --- | --- |
| `dest` | Path to the remote developer file system directory you would like to list files for. If omitted, defaults to the account root. |

### Fetch files

Fetch a file, or directory and its child folders and files, by path. Copies the files from your HubSpot account into your local environment.By default, fetching will not overwrite existing local files. To overwrite local files, include the `--overwrite` flag.

```
hs fetch --account=<name> <src> [dest]
hs filemanager fetch --account=<name> <src> [dest]
```

**Arguments**

| Argument | Description |
| --- | --- |
| `src` (Required) | Path in HubSpot Design Tools |
| `dest` | Path to the local directory you would like the files to be placed, relative to your current working directory. If omitted, this argument will default to your current working directory. |

**Flags**

| Options | Description |
| --- | --- |
| `--account` | Specify an `accountId` or name to fetch fromSupports an alias of `--portal` for backward compatibility with older versions of the CLI. |
| `--overwrite` | Overwrite existing files with fetched files. |
| `--mode` | Specify if fetching a draft or published version of a file from HubSpot. [Click here](http://developers.hubspot.com/docs/developer-tooling/local-development/hubspot-cli/reference#modes) for more info |

### Upload files

Upload a new local asset to your HubSpot account. Changes uploaded through this command will be live immediately.

```
hs upload --account=<name> <src> <dest>
hs filemanager upload --account=<name> <src> <dest>
```

**Arguments**

| Argument | Description |
| --- | --- |
| `src` (Required) | Path to the local file, relative to your current working directory. |
| `dest` (Required) | Path in HubSpot Design Tools, can be a net new path. |

**Flags**

| Options | Description |
| --- | --- |
| `--account` | Specify a `accountId` or name to fetch from.Supports an alias of `--portal` for backward compatibility with older versions of the CLI. |
| `--mode` | Specify if uploaded files are published in HubSpot. [See “modes”](http://developers.hubspot.com/docs/developer-tooling/local-development/hubspot-cli/reference#modes) for more info. |
| `--clean` | An optional flag that will delete the destination directory and its contents before uploading. |

**Subcommands**

| Subcommands | Description |
| --- | --- |
| `filemanager` | Uploads the specified src directory to the [File Manager](https://developers.hubspot.com/docs/guides/cms/storage/file-manager), rather than to the [developer file system](https://developers.hubspot.com/docs/guides/cms/overview#developer-file-system) in the Design Manager.**Note**: Uploaded files will be set to _public_, making them viewable by anyone with the URL. See our [help documentation](https://knowledge.hubspot.com/files/organize-edit-and-delete-files#edit-the-file-visibility-setting) for more details on file visibility settings. |

### Set a watch for automatic upload

Watch your local directory and automatically upload changes to your HubSpot account on save. Any changes made when saving will be live immediately.Keep the following in mind when using `watch`:

*   Deleting watched files locally will not automatically delete them from HubSpot. To delete files, use `--remove`.
*   Renaming a folder locally will upload a new folder to HubSpot with the new name. The existing folder in HubSpot will not be deleted automatically. To delete the folder, use `--remove`.

```
hs watch --account=<name> <src> <dest>
```

**Arguments**

| Argument | Description |
| --- | --- |
| `src` (Required) | Path to the local directory your files are in, relative to your current working directory. |
| `dest` (Required) | Path in HubSpot Design Tools, can be a net new path. |

**Flags**

| Flag | Description |
| --- | --- |
| `--account` | Specify a `accountId` or name to fetch fromSupports an alias of `--portal` for backward compatibility with older versions of the CLI. |
| `--mode` | Specify if uploaded files are published or saved as drafts in HubSpot. [Learn more about using modes](http://developers.hubspot.com/docs/developer-tooling/local-development/hubspot-cli/reference#modes). |
| `--initial-upload` | Upload the directory before watching for updates. Supports an alias of `-i`. |
| `--remove` | Will cause watch to delete files in your HubSpot account that are not found locally. |
| `--notify=` | log to specified file when a watch task is triggered and after workers have gone idle. |

### Move files

Moves files within the [developer file system](https://developers.hubspot.com/docs/guides/cms/overview#developer-file-system) from one directory to another. Does not affect files stored locally.

```
hs mv --account=<name> <src> <dest>
```

**Arguments**

| Argument | Description |
| --- | --- |
| `src` (Required) | Path to the remote developer file system directory your files are in. |
| `dest` (Required) | Path to move assets to within the developer file system. |

**Flags**

| Flag | Description |
| --- | --- |
| `--account` | Specify a `accountId` or name to move files within. Supports an alias of `--portal` for backward compatibility with older versions of the CLI. |

### Create new files

Creates the folder/file structure of a new asset.

```
hs create <type> <name> [dest]
```

**Arguments**

| Argument | Description |
| --- | --- |
| `type` (Required) | Type of asset. Supported types include: * [`module`](https://developers.hubspot.com/docs/guides/cms/content/modules/overview) * [`template`](https://developers.hubspot.com/docs/guides/cms/content/templates/overview) * [`website-theme`](https://developers.hubspot.com/docs/guides/cms/content/themes/hubspot-cms-boilerplate) * [`function`](https://developers.hubspot.com/docs/reference/cms/serverless-functions) * [`webpack-serverless`](https://github.com/HubSpot/cms-webpack-serverless-boilerplate) * [`react-app`](https://github.com/HubSpot/cms-react-boilerplate) * [`vue-app`](https://github.com/HubSpot/cms-vue-boilerplate) |
| `name` (Required) | The name of the new asset. |
| `dest` | The destination folder for the new asset, relative to your current working directory. If omitted, this will default to your current working directory. |

### Remove files

Deletes files, or folders and their files, from your HubSpot account. This does not delete the files and folders stored locally. This command has an alias of `rm`.

```
hs remove --account=<name> <path>
```

**Arguments**

| Argument | Description |
| --- | --- |
| `path` (Required) | The path of the file or folder in HubSpot’s developer file system. |

**Flags**

| Flag | Description |
| --- | --- |
| `--account` | Specify a `accountId` or name to remove a file from.Supports an alias of `--portal` for backward compatibility with older versions of the CLI. |

### Ignore files

You can include a `.hsignore` file to specify files that should not be tracked when using the CLI. This file functions similar to how `.gitignore` files work. Files matching the patterns specified in the `.hsignore` file will not be uploaded to HubSpot when using the [`upload`](https://developers.hubspot.com/docs/developer-tooling/local-development/hubspot-cli/reference#upload) or [`watch`](https://developers.hubspot.com/docs/developer-tooling/local-development/hubspot-cli/reference#watch) commands.

```
# ignore all files within a specific directory
/ignore/ignored
# ignore a specific file
/ignore/ignore.md
# ignore all .txt files
*.txt
# ignore all log files - useful if you commonly output serverless function logs as files.
*.log
```

Locally preview theme
---------------------

When developing a theme, you can run `hs theme preview` in the theme’s root directory to render a live preview of your changes without uploading files to the account. The preview will run on a local proxy server at [https://hslocal.net:3000/](https://hslocal.net:3000/).Once run, this command will run a watch process so that any saved changes are rendered in the preview.

```
hs theme preview <src> <dest>
```

**Arguments**

| Argument | Description |
| --- | --- |
| `src` (Required) | Path to the local file, relative to your current working directory. This command should be run in the theme’s root directory.. |
| `dest` (Required) | The path for the preview. This can be any value, and is only used internally and for display purposes on the preview page. |

The main page at [https://hslocal.net:3000/](https://hslocal.net:3000/) will display a list of your theme’s templates and modules, all of which can be individually previewed by clicking the provided links. You’ll also see a list of the account’s connected domains, which you can use to preview content on specific domains. The domain will be prepended to the `hslocal.net` domain.![Image 1: local-theme-preview-homepage](https://knowledge.hubspot.com/hubfs/Knowledge_Base_2023_2024/local-theme-preview-homepage.png)

HubDB Commands
--------------

Use these commands to create, delete, fetch, and clear all rows of a HubDB table. The HubSpot account must have access to HubDB to use these commands.

### Create HubDB table

Create a new HubDB table in the HubSpot account.

```
hs hubdb create --path [path] --account [account]
```

**Flags**

| Flag | Description |
| --- | --- |
| `--path` (Required) | The local [JSON file](http://developers.hubspot.com/docs/developer-tooling/local-development/hubspot-cli/reference#hubdb-table-json) to use to generate the HubDB table. |
| `--account` | Specify a `accountId` or name to create HubDB in. Supports an alias of `--portal` for backward compatibility with older versions of the CLI. |

### Fetch HubDB Table

Download a HubDB table’s data to your local machine.

```
hs hubdb fetch <table-id> <dest>
```

**Arguments**

| Argument | Description |
| --- | --- |
| `table-id` (Required) | HubDB table id found in the HubDB dashboard. |
| `dest` | The local path destination to store the [`hubdb.json`](http://developers.hubspot.com/docs/developer-tooling/local-development/hubspot-cli/reference#hubdb-table-json) file. |

When you fetch a HubDB the data is stored as `tablename.hubdb.json`. When you create a new table you must specify a source JSON file. Below is an example of a table in JSON format.

```
{
  "name": "store_locations",
  "useForPages": true,
  "label": "Store locations",
  "allowChildTables": false,
  "allowPublicApiAccess": true,
  "dynamicMetaTags": { "DESCRIPTION": 3, "FEATURED_IMAGE_URL": 7 },
  "enableChildTablePages": false,
  "columns": [
    { "name": "name", "label": "Name", "type": "TEXT" },
    {
      "name": "physical_location",
      "label": "Physical Location",
      "type": "LOCATION"
    },
    { "name": "street_address", "label": "Street address", "type": "TEXT" },
    { "name": "city", "label": "City", "type": "TEXT" },
    {
      "name": "state",
      "label": "State",
      "options": [
        { "id": 1, "name": "Wisconsin", "type": "option", "order": null },
        { "id": 2, "name": "Minnesota", "type": "option", "order": null },
        { "id": 3, "name": "Maine", "type": "option", "order": null },
        { "id": 4, "name": "New York", "type": "option", "order": null },
        { "id": 5, "name": "Massachusetts ", "type": "option", "order": null },
        { "id": 6, "name": "Mississippi", "type": "option", "order": null },
        { "id": 7, "name": "Arkansas", "type": "option", "order": null },
        { "id": 8, "name": "Texas", "type": "option", "order": null },
        { "id": 9, "name": "Florida", "type": "option", "order": null },
        { "id": 10, "name": "South Dakota", "type": "option", "order": null },
        { "id": 11, "name": "North Dakota", "type": "option", "order": null },
        { "id": 12, "name": "n/a", "type": "option", "order": null }
      ],
      "type": "SELECT",
      "optionCount": 12
    },
    { "name": "phone_number", "label": "Phone Number", "type": "TEXT" },
    { "name": "photo", "label": "Store Photo", "type": "IMAGE" }
  ],
  "rows": [
    {
      "path": "super_store",
      "name": "Super Store",
      "isSoftEditable": false,
      "values": {
        "name": "Super Store",
        "physical_location": {
          "lat": 43.01667,
          "long": -88.00608,
          "type": "location"
        },
        "street_address": "1400 75th Greenfield Ave",
        "city": "West Allis",
        "state": { "id": 1, "name": "Wisconsin", "type": "option", "order": 0 },
        "phone_number": "(123) 456-7890"
      }
    },
    {
      "path": "store_123",
      "name": "Store #123",
      "isSoftEditable": false,
      "values": {
        "name": "Store #123",
        "physical_location": {
          "lat": 32.094803,
          "long": -166.85889,
          "type": "location"
        },
        "street_address": "Pacific Ocean",
        "city": "at sea",
        "state": { "id": 12, "name": "n/a", "type": "option", "order": 11 },
        "phone_number": "(123) 456-7891"
      }
    }
  ]
}
```

### Clear rows in a HubDB table

Clear all of the rows in a HubDB table.

```
hs hubdb clear <tableId>
```

**Arguments**

| Argument | Description |
| --- | --- |
| `tableId` (Required) | HubDB table id found in the HubDB dashboard. |

**Flags**

| Flag | Description |
| --- | --- |
| `--account` | Specify a `accountId` or name to clear HubDB rows from.Supports an alias of `--portal` for backward compatibility with older versions of the CLI. |

### Delete HubDB table

Deletes the specified HubDB table from the account. You will be prompted to confirm the deletion before proceeding. You can use the `--force` flag to bypass this confirmation.

```
hs hubdb delete <table-id>
```

**Arguments**

| Argument | Description |
| --- | --- |
| `table-id` (Required) | HubDB table ID found in the HubDB dashboard. |

**Flags**

| Flag | Description |
| --- | --- |
| `--account` | Specify a `accountId` or name to delete HubDB from. Supports an alias of `--portal` for backward compatibility with older versions of the CLI. |
| `--force` | Bypass the confirmation prompt and immediately delete the table once the command is executed. |

Managing secrets
----------------

### Add a secret

Add a secret to your account which can be used to reference authentication data you don’t want to expose in your project files.To expose the secret to your function, update your file with the secret’s name, either to the specific endpoints you want to use it in or globally to make it available to all.

```
hs secrets add <secret-name>
```

**Arguments**

| Argument | Description |
| --- | --- |
| `secret-name` (Required) | Name of the secret to add. |

### Update a secret

Update the value of a secret in your account which can be referenced in your project without exposing it directly in your source files.

```
hs secrets update <secret-name>
```

**Arguments**

| Argument | Description |
| --- | --- |
| `secret-name` (Required) | The name of the secret, which you’ll later use to reference the secret. This can be any unique value, though it’s recommended to keep it simple for ease of use. |

### Remove a secret

Remove a secret from your account, making it no longer usable within your project files. You will be prompted to confirm the deletion before proceeding. You can use the `--force` flag to bypass this confirmation.

```
hs secrets delete <secret-name>
```

**Arguments**

| Argument | Description |
| --- | --- |
| `secret-name` (Required) | Name of secret you want to remove. |

**Flags**

| Flag | Description |
| --- | --- |
| `--force` | Bypass the confirmation prompt and immediately delete the table once the command is executed. |

### List secrets

List secrets within your account to know what you have stored already using the add secrets command.

```
hs secrets list
```

Open browser shortcuts
----------------------

There are so many parts of the HubSpot app that developers need to access frequently. To make it easier to get to these tools you can open them directly from the command line. Your `defaultAccount` or `--account` argument will be used to open the associated tool for that account.

### open

```
hs open <shortcut-name or alias>
```

**Arguments**

| Argument | Description |
| --- | --- |
| `shortcut` (Required) | Provide the full shortcut name or alias of the short cut you wish to open in your browser. |

```
hs open --list
```

**Arguments**

| Argument | Description |
| --- | --- |
| `--list` (Required) | Lists all of the shortcuts, their aliases and destinations. |

Command completion
------------------

If you use the CLI frequently, it can be useful to be-able-to tab to auto-complete commands.

```
hs completion >> ~/.bashrc
```

For Mac OS X

```
hs completion >> ~/.bash_profile
```

Evaluate themes and templates for SEO and accessibility
-------------------------------------------------------

Uses [Google’s Lighthouse tools](https://developer.chrome.com/docs/lighthouse/overview) to score the quality of your themes and templates for their adherence to the following categories:

*   Accessibility
*   Web best practices
*   Performance
*   PWA
*   SEO

The following types of templates are scored:

*   landing pages
*   website pages
*   Blog posts
*   Blog listing page

If any templates fail to generate a score because of Lighthouse errors, a list of these templates will be provided.

```
hs cms lighthouse-score --theme=path
```

**Flags**

| Flag | Description |
| --- | --- |
| `--theme-path` (Required) | Path to a theme in the Design Manager. |
| `--verbose` | * When this parameter is excluded, the returned score is an average of all the theme’s templates (default). * When this parameter is included, the individual template scores are shown. You’ll also receive [Lighthouse report](https://developer.chrome.com/docs/lighthouse/overview/#report-viewer) links for each template. |
| `--target` | This can either be desktop or mobile to see respective scores. By default, the target is desktop. |

### Retrieve an existing React theme

To fetch an existing React theme from your account, use the following command:

```
hs cms get-react-module <name> <dest>
```

**Arguments**

| Argument | Description |
| --- | --- |
| `name` | The name of the module to download. |
| `dest` | The destination on your local machine to download the module to. |

Generate theme field selectors for in-app highlighting
------------------------------------------------------

When creating a theme, use the following command to generate an `editor-preview.json` file which maps CSS selectors to theme fields. This enables content creators to see which theme elements will be impacted by updates to a field’s styling options.After running the command, you’ll need to review and refine the `editor-preview.json` file to ensure that fields and selectors are mapped properly. While this command will make a rudimentary guess as to which fields affect which selectors, you’ll need to make corrections based on how your theme is built. For example, this command cannot detect when modules are overriding styling or when you’re using macros. Learn more about [theme editor field highlighting](https://developers.hubspot.com/guides/cms/content/fields/overview#theme-editor-field-highlighting).

```
hs theme generate-selectors <themePath>
```

Modes
-----

The `\--mode` option allows you to determine if local changes are published when uploaded to HubSpot. This option can be used in each command or set as a default in your `hubspot.config.yml` file.The two options for `\--mode` are `\--mode=draft` and `\--mode=publish.`The following is the order of precedence for setting `\--mode`:

1.   Using `\--mode` in a command will override all other settings.
2.   Setting a `defaultMode` for each account in your `hubspot.config.yml file`, removes the need to use `\--mode` in each command. It will override the top-level setting.
3.   Setting a `defaultMode` at the top-level in your `hubspot.config.yml file`, sets a default`\--mode` for all accounts. It will override the default behavior.
4.   The default behavior for `\--mode` is `publish`.

Environment variables
---------------------

The HubSpot CLI supports the use of environment variables, this can be especially useful when creating automations like a GitHub Action.Run any command using the `--use-env` flag to use the environment variables instead of the `hubspot.config.yml`.

```
hs upload example-project example-project-remote --use-env
```

| Name | Description |
| --- | --- |
| `HUBSPOT_ACCOUNT_ID` (Required) | The HubSpot account ID. |
| `HUBSPOT_PERSONAL_ACCESS_KEY` (Recommended) | The [personal access key](https://developers.hubspot.com/docs/guides/cms/tools/personal-access-key) of a user on the HubSpot account. All updates made will be associated to this user. |
| `HUBSPOT_CLIENT_ID` | The OAuth client ID. |
| `HUBSPOT_CLIENT_SECRET` | The OAuth secret. |

Marketplace asset validation
----------------------------

The CLI provides a suite of automated tests you can perform on your assets to get them in-line with the marketplace requirements prior to submitting. Passing all automated tests does not mean you will for sure pass the review process, further review is conducted to ensure quality beyond what can be easily automated.

### Validate theme

The theme validation command allows you to quickly run automated tests on your theme to identify problems that need to be fixed prior to submission to the asset marketplace. These will be returned in your CLI as a list of [error] and [success] messages separated into groups that represent types of assets within a theme.Before you can validate a theme, you’ll first need to upload it to your account with `hs upload`. Then, run the following command to validate the uploaded theme.

```
hs theme marketplace-validate <path>
```

**Arguments**

| Argument | Description |
| --- | --- |
| `path` (Required) | Root relative path to the theme folder in the design manager. |

### Validate module

Similar to validating a theme, this command allows you to quickly run automated tests on a module to identify problems that need to be fixed prior to submission to the asset marketplace.Before you can validate a module, you’ll first need to upload it to your account with `hs upload`. Then, run the following command to validate the uploaded module.

```
hs module marketplace-validate <src>
```

**Arguments**

| Argument | Description |
| --- | --- |
| `src` (Required) | Root relative path to the module folder in the design manager. |

Custom objects
--------------

Manage custom objects using the `schema` subcommand to manage custom object schemas and the `create` subcommand to create a new custom object.

### Fetch schema for a single custom object

To fetch the schema for an existing custom object, run the following command:

```
hs custom-object schema fetch <name> <dest>
```

**Arguments**

| Argument | Description |
| --- | --- |
| `name` | The name of the custom object to fetch the schema for. |
| `dest` | The destination on your local machine to save the schema to. |

### Fetch schema for all custom objects

Fetch the schemas for all custom objects in an account.

```
hs custom-object schema fetch-all <dest>
```

**Arguments**

| Argument | Description |
| --- | --- |
| `dest` | The destination on your local machine to save the schemas to. |

### Update the schema for a custom object

Update the schema for an existing custom object with the definition at the provided path.

```
hs custom-object schema update --path=definition
```

**Flags**

| Flag | Description |
| --- | --- |
| `--path` | The path to a schema definition located on your local machine. |

### Delete the schema for a custom object

Delete the schema for an existing custom object. You will be prompted to confirm the deletion before proceeding. You can use the `--force` flag to bypass this confirmation.

```
hs custom-object schema delete <name>
```

**Arguments**

| Flag | Description |
| --- | --- |
| `name` | The name of the custom object schema to delete. |

### Create a new custom object

Create a new custom object with the provided definition for its schema.

```
hs custom-object create <name> --path=definition
```

**Arguments**

| Flag | Description |
| --- | --- |
| `name` | The name of your new custom object schema. |

**Flags**

| Flag | Description |
| --- | --- |
| `--path` | The path to a schema definition located on your local machine. |

Projects and sandboxes
----------------------

A full reference of project-related commands, as well as any commands related to managing your sandboxes, can be found in [this article](https://developers.hubspot.com/docs/developer-tooling/local-development/hubspot-cli/project-commands).

----------------------

Title: Projects and sandboxes CLI reference - HubSpot docs

URL Source: http://developers.hubspot.com/docs/developer-tooling/local-development/hubspot-cli/project-commands

Markdown Content:
Last modified: August 22, 2025

The HubSpot command line interface (CLI) connects your local development tools to HubSpot, allowing you to develop on HubSpot with version control, your favorite text editor, and various web development technologies.Below, learn about the CLI commands available while you’re developing with HubSpot projects. You can also refer to the [standard CLI commands](https://developers.hubspot.com/docs/developer-tooling/local-development/hubspot-cli/reference) reference for general commands such as `hs auth`.The current recommended version of the HubSpot CLI is `7.6.0` or later.

Update the CLI
--------------

Update your CLI to the latest version.

```
npm install -g @hubspot/cli@latest
```

View all commands
-----------------

List all project-specific CLI commands.

```
hs project help
```

Create a new project
--------------------

Create a project in a specified directory. You’ll be prompted to give the project a name, as well as confirm the local location. You’ll then select whether to start the project from scratch or from a sample template.Learn more about the project structure and how to get started in the [app creation guide](https://developers.hubspot.com/docs/apps/developer-platform/build-apps/create-an-app).Once you’ve created a project, you can run other project commands inside your project directory and HubSpot will automatically recognize your project.

```
hs project create --platform-version 2025.2
```

Upload to HubSpot
-----------------

Upload the project to your HubSpot account and create a build. If the project hasn’t been created in the account yet, you’ll be asked whether you want to create it.If the project is configured to auto-deploy, this command will automatically deploy after the build is successful. By default, new projects are set to auto-deploy.

```
hs project upload
```

You can upload a project to a specific account in your `~/.hscli/config.yml` file by adding `--account=accountName` to the command. For example, `hs project upload --account=main`. This can be useful when switching between uploading to a sandbox account and then uploading to the main account. For example, your workflow might look like:

*   When developing your project in a sandbox, you upload changes with `hs project upload --account=sandbox`.
*   Then when uploading the project to a main account, you upload the project with `hs project upload --account=main`.

You can use the same configuration when using the [watch](http://developers.hubspot.com/docs/developer-tooling/local-development/hubspot-cli/project-commands#watch-for-changes) command.

Deploy to HubSpot
-----------------

Manually deploy the most recent build if the project is not set to auto-deploy.

```
hs project deploy
```

Migrate a public app
--------------------

Migrate an existing public app to the new developer projects framework (`v2025.2`). Learn more in the [public app migration guide](https://developers.hubspot.com/docs/apps/developer-platform/build-apps/migrate-an-app/migrate-an-existing-public-app).

```
hs app migrate
```

Start a local development server
--------------------------------

Start a local development server to view extension changes in the browser without needing to refresh. With the server running, saving changes to any JSX files when you’re developing an [app card](https://developers.hubspot.com/docs/apps/developer-platform/add-features/ui-extensibility/app-cards/create-an-app-card) or [settings page](https://developers.hubspot.com/docs/apps/developer-platform/add-features/ui-extensibility/create-a-settings-component) using UI components will cause the page to automatically refresh. This does not include changes made to the `.json` config files, which need to be manually uploaded using the `hs project upload` command instead.

```
hs project dev
```

Open project in HubSpot
-----------------------

Opens the project in HubSpot where you can view the project’s settings, build history, and more. By default, will attempt to open the project in the default account set in `~/.hscli/config.yml`. Specify an account by adding the `--account=accountName` flag.

```
hs project open
```

Watch for changes
-----------------

Watches the project directory and uploads to HubSpot upon saving, including deleting files. Each upload will result in a new build with a new build ID. A successful build will deploy automatically if the project’s [auto-deploy setting](https://developers.hubspot.com/docs/apps/developer-platform/build-apps/manage-apps-in-hubspot) is turned on.

```
hs project watch
```

You can further configure watch to send changes to a specific account with `---account=accountName`. For example, `hs project watch --account=main`.

View logs
---------

Get logs for a specific function within a project.

```
hs project logs
```

Running this command will guide you through selecting the project and app to get logs for. However, you can also manually specify this information by including the following flags in the command:

| Flag | Description |
| --- | --- |
| `--project=projectName` | The name of the project as set in the `hsproject.json` file. |
| `--app=appName` | The name of the app as set in the `app.json` file. |

Sandbox commands
----------------

Interact with [standard sandboxes](https://knowledge.hubspot.com/account-management/set-up-a-hubspot-standard-sandbox-account) and [development sandboxes](https://developers.hubspot.com/docs/developer-tooling/overview#create-and-use-development-sandboxes) using the commands below.

### Create a sandbox

Creates a new sandbox in a production account. When running this command, you can select whether you want to create a standard sandbox or a development sandbox.If creating a standard sandbox, when running this command, all supported assets will be synced from production to the standard sandbox by default. You can choose to trigger a one-time sync of the last updated 5,000 contacts and, if applicable, up to 100 associated companies, deals, and tickets (for each associated object type).A production account can have one standard sandbox and two development sandboxes at a time. Additional standard sandboxes can be purchased as an [add-on](https://legal.hubspot.com/hubspot-product-and-services-catalog#Addons). Learn more about [development sandbox limits](https://developers.hubspot.com/docs/developer-tooling/overview#create-and-use-development-sandboxes).

```
hs sandbox create
```

### Delete a sandbox

Deletes a sandbox connected to the production account. Follow the prompts to select the sandbox account to delete, then confirm the permanent deletion.

```
hs sandbox delete
```

Create and use development sandboxes
------------------------------------

After following the steps above to connect a production account to the CLI for private app development, you can create a development sandbox within it to setup a lightweight testing environment. This enables you to develop your apps and extensions in a siloed environment before deploying to a production account.Before proceeding, review the following development sandbox limits:

*   A production account can have only one development sandbox at a time.
*   CRM object definitions are synced from the production account to the development sandbox at the time of sandbox creation.
*   You cannot create a sandbox within another sandbox.

### Create a development sandbox

To set up a development sandbox account:

*   Because development sandboxes are created within the `defaultPortal` in your `hubspot.config.yml` file, first confirm that your production account is connected and set as the default:
    *   In the terminal, run `hs accounts list`.
    *   In your list of connected accounts, confirm that your production account is listed as the default account.![Image 1: hs-acounts-list-default](https://www.hubspot.com/hubfs/Knowledge_Base_2021/Developer/hs-acounts-list-default.png)
    *   If your production account is not the default, run `hs accounts use` and select your production account.

*   After confirming your production account is the default, run `hs sandbox create`.
*   You’ll then be prompted to select a type of sandbox to create. Select **Development sandbox**, then press **Enter**.
*   Enter a `name` for the sandbox account, then press **Enter**.
*   All CRM object definitions will be copied from production to the development sandbox.
*   You can use the [import tool](https://knowledge.hubspot.com/import-and-export/import-objects) to import production object record data, or manually create sample data for testing.
*   The CLI will then begin the sandbox setup process. Once the sandbox is fully set up and synced, you’ll see a _Sandbox sync complete_ confirmation.

With your development sandbox created, it will appear under the associated production account when running `hs accounts list`.If you want to set the development sandbox as your default account, run `hs accounts use`, then select the **sandbox**. To deploy to your sandbox or production account, you can either run `hs accounts use` to set the default account, or manually select the account when uploading by running `hs project upload --account=<name-of-account>`.![Image 2: cli-connected-accounts-sandbox](https://www.hubspot.com/hubfs/Knowledge_Base_2021/Developer/cli-connected-accounts-sandbox.png)Development sandboxes are designed to be early proof of concept environments. It is recommended to [delete](http://developers.hubspot.com/docs/developer-tooling/local-development/hubspot-cli/project-commands#delete-a-development-sandbox) and [create](http://developers.hubspot.com/docs/developer-tooling/local-development/hubspot-cli/project-commands#create-a-development-sandbox) a new Development Sandbox using the CLI. This ensures development sandboxes always have an exact mirror of the production account’s CRM object definitions when beginning new projects.After setting up your development sandbox, learn how to create a [UI extension](https://developers.hubspot.com/docs/apps/developer-platform/add-features/ui-extensibility/ui-components/overview), or learn more about [creating apps](https://developers.hubspot.com/docs/apps/developer-platform/build-apps/create-an-app).

### View a development sandbox in HubSpot

By default, all super admin users are synced to the development sandbox during creation. Super admins can give other users access by [adding them as users to the development sandbox](https://knowledge.hubspot.com/account-management/add-and-remove-users).To access the development sandbox account in HubSpot:

*   In your HubSpot account, navigate to **CRM Development** in the main navigation bar.
*   In the left sidebar menu, select **Sandboxes**.
*   Click the **Development** tab, where your new sandbox will be listed along with its name, create date, and the user who created it.
*   To navigate to the sandbox account, click the **development sandbox name**.

Once a user has been granted access to a development sandbox, they can access it by clicking the **Profile picture** in the top right of HubSpot, then clicking the **Account selection menu** and selecting the account.![Image 3: portal-picker-hobbes](https://www.hubspot.com/hubfs/Knowledge_Base_2021/portal-picker-hobbes.png)

### Delete a development sandbox

*   To delete a development sandbox using the CLI, run `hs sandbox delete`, then follow the prompts.
*   To delete a development sandbox in HubSpot:
    *   In your HubSpot account, navigate to **CRM Development** in the main navigation bar.
    *   In the left sidebar menu, select **Sandboxes**.
    *   Click the **Development** tab.
    *   Hover over the development sandbox, then click **Delete**.

![Image 4: delete-development-sandbox](https://www.hubspot.com/hubfs/Knowledge_Base_2023/delete-development-sandbox.png)