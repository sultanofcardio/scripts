# Git remote conversion

For when you've finally decided to stop using HTTPS git URLs, but don't want to change all your remotes manually.

Convert all your git remote URLs from HTTPS to SSH:
```shell script
git-https-to-ssh.sh [search_dir]
```

Sample output:

```text
Searching from /path/to/search_dir
Found /path/to/search_dir/repo_name/.git
Replacing <remote_name>/https://github.com/someone/reponame with git@github.com:someone/reponame.git

```

Works for remote URLs with or without username:token prepended
