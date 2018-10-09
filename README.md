jc, the JSON Configurator
======================================================================


This tiny utility was written (on top of the AMAZING `jq`) to provide me with a means to idempotently write configuration values in a concise way. The utility should really be thought of as a fancy suit for `jq`: it makes the specific task of writing -- but not _overwriting_ -- config values easier.

My use-case for this was almost always in package setups. I would release a package (usually a Debian package) that captured some user-defined config values via `debconf`, then wrote those values to a config file. Later, however, I would add config values, or I would need to change certain values, and that meant either doing a lot of legwork with jq in the package's post-install script, or doing some very unreliable grepping and sedding.

Thus, `jc` was born.

Here's the help I wrote for it:

```
USAGE

      jc (-hvif) | [confkey] [confvalue] ([conffile])

DESCRIPTION

      This utility allows you to idempotently set config values in a json config file. It uses jq to do
      its work, and by default won't override keys that are already set. (Pass the -f|--force flag to
      force set a value.)

      While it works fine with a [conffile] argument, you may also leave the last argument off to read
      from STDIN. This lets you pipe many calls together into a string that results in a final, finished
      config string, which you may then write to file.

      Note that jc will attempt to guess the type of value you're sending. For example, if the value is
      'true', 'false', 'null' or numeric, it will use those json native types. Otherwise, it will quote
      values that are not already quoted.

OPTIONS

      -h|--help               Display this help text

      -v|--version            Display version information

      -i|--in-place           Write back to the config file without printing to STDOUT. Note that this
                              (obviously) requires that you pass the conffile argument.

      -f|--force              Force a config key to be set to the value given, even if it's already set.
                              Normally, config values that already exist are not overridden, but you can
                              change that behavior by passing this flag.

DEPENDENCIES

      * bash > 4
      * jq > 1.5

KNOWN PROBLEMS

      * jc does not currently handle anything but regular objects (i.e., you can't mess with arrays.). There
        are nominally plans to support arrays, but there are simply not enough hours in the day right now.
      * it also doesn't do well with special characters like dashes
```


## Use Cases

To illustrate how you would use it, suppose you have a config file, ~/my-config.json that was installed in some package:

```json
{
  "database": {
    "default": {
      "socket": "/some/path/to/socket",
      "username": "my-user",
      "password": "my-pass"
    },
    "debug": false
  }
}
```

You might have created and installed the package some time ago, before you added the `email` config section. When you update the package, you might use the following to ensure the config is in the correct state:

```sh
cat ~/my-config.json | \
jc database.default.username "$DB_USER" | \
jc database.default.password "$DB_PASS" | \
jc database.debug true | \
jc email.stubAddress "$USERS_EMAIL" | \
tee ~/my-config.json >/dev/null
```

The above would result in a ~/my-config.json file like this:

```json
{
  "database": {
    "default": {
      "socket": "/some/path/to/socket"
      "username": "my-user",
      "password": "my-pass"
    },
    "debug": false
  },
  "email": {
    "stubAddress": "my-email@humans.org"
  }
}
```

**Important:** Notice that `database.debug` is still set to false, even though our script said to set it to true. With config, it's always important to recognize that the user may change config values hirmself, and that you shouldn't overwrite values that are already writen unless you know them to be wrong (which you can check for in your script using naked `jq`).

Also note that unfortunately, because of the way the shell works, you MUST use `tee` or a temp file, since trying to redirect the output to the file you're catting from will zero out the file before it gets read. (I.e., don't do this: `cat ~/my-config.json | jc database.debug true > ~/my-config.json` because you'll get a blank file with no warning.)

