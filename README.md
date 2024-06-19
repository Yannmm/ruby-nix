# Ruby Nix

This is technically a fork of `bundlerEnv` that attempts to better meet the needs of ruby app developers instead of package maintainers.

This flake exports a function that is suitable for application development (eg. Rails).

## Tl;dr
The `gemset.nix` file, generated by executing the `bundix` command, manages your environment. Bundix depends on the contents of `Gemfile.lock`, which is produced by running the `bundle lock` command after modifying the `Gemfile`.

```
Gemfile --[bundle lock]-->
Gemfile.lock --[bundix]-->
gemset.nix --[nix develop (actual build)]-->
reproducible ruby environment
```

## Features

1. supports local, path-based gems
2. supports git sources
3. supports pre-compiled native gems on multiple platforms (see [this discussion](https://github.com/nix-community/bundix/pull/68))
4. bundix out of the box
5. A starter template based on flake

## How is it different from bundlerEnv?

1. it does not track the entire directory as `inputSrc` when `gemDir` is specified, requiring only `gemset.nix`.
2. it does not use `BUNDLE_GEMFILE` variable.
3. it works without `Gemfile` and `Gemfile.lock`.

## The gist

``` nix
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ ruby-nix.overlays.ruby ];
        };
        rubyNix = ruby-nix.lib pkgs;

        inherit (rubyNix {
          name = "simple-ruby-app";
          gemset = ./gemset.nix;
        })
          env ruby;
      in {
        devShells = rec {
          default = dev;
          dev = pkgs.mkShell { buildInputs = [ env ruby ]; };
        };
      });
```

## Global Bundix Installation (optional)

My bundix [fork](https://github.com/inscapist/bundix) is needed to generate the correct `gemset.nix`. It is available in nix shell out of the box. 


``` sh
# installation
nix profile install github:inscapist/bundix/main

# upgrade
nix profile upgrade '.*'
```

## Usage

With nix [installed](/docs/nix-installation.md) and optionally [direnv](/docs/direnv.md), you can run:

#### 1. Initialize flake

``` sh
cd myapp
nix flake init -t github:inscapist/ruby-nix/main
```

#### 2. Enter nix shell

If you are a [direnv](/docs/direnv.md) user, add the following content to `.envrc` and run `direnv allow`. Otherwise, run `nix develop -c zsh`.

```
if ! has nix_direnv_version || ! nix_direnv_version 3.0.4; then
    source_url "https://raw.githubusercontent.com/nix-community/nix-direnv/3.0.4/direnvrc" "sha256-DzlYZ33mWF/Gs8DDeyjr8mnVmQGx7ASYqA5WlxwvBG4="
fi

watch_file gemset.nix
use flake
```

Or use the latest version [here](https://github.com/nix-community/nix-direnv/blob/master/templates/flake/.envrc). Don't forget to add `watch_file /path_to/gemset.nix` to ensure direnv picks up gem changes.

#### 3. In nix shell

In a nix shell, you have `ruby`, `irb`, `bundle` at your disposal. Additional gems will only be available if they are specified in `gemset.nix`. To generate that, ensure `Gemfile` and `Gemfile.lock` are present, then run `bundix`. 

## FAQs

### 1. When does my environment gets build?
If you use direnv, running `git add gemset.nix` would trigger a rebuild automatically.

Otherwise, Ctrl-D to exit the current nix shell, and enter again.


### 2. How to `bundle`?

With ruby-nix, you shouldn't install gems using bundle. Nix will build the gems for you. **Always run `bundix` to update your gemset after making changes to Gemfile.lock.**. If you faced error with `git fetch`, set `BUNDLE_PATH=vendor/bundle` in your environment.

#### bundle add
run `bundle add GEM --skip-install` instead

#### bundle install (after modifying Gemfile)
run `bundle lock` instead

#### bundle update GEM
run `bundle lock --update=GEM` instead

#### Adding multiple platforms to Gemfile.lock

One example could be:

``` sh
bundle lock --update --add-platform ruby arm64-darwin-21 x86_64-darwin-20 x86_64-linux
```

You can retrieve the platform names by running `bundle platform`. Having multiple platforms would allow your colleagues to use precompiled gems, if they are available.

In your Gemfile.lock, it should show up as:
```
   sorbet-runtime (0.5.10626)
    sorbet-static (0.5.10626-universal-darwin-20)
    sorbet-static (0.5.10626-universal-darwin-21)
    sorbet-static (0.5.10626-universal-darwin-22)
    sorbet-static (0.5.10626-x86_64-linux)
    sorbet-static-and-runtime (0.5.10626)
      sorbet (= 0.5.10626)
@@ -1232,6 +1233,7 @@ GEM
PLATFORMS
  arm64-darwin-20
  arm64-darwin-21
  arm64-darwin-22
  x86_64-darwin-20
  x86_64-darwin-21
  x86_64-linux
```
### 3. `bundle lock` fails with `Permission denied` when Gemfile contains git sources

``` sh
export BUNDLE_PATH=vendor/bundle 
bundle lock
rm -rf vendor/bundle
```

also remove or rename `.bundle` if it continues to fail.

### 4. How to use a different ruby version?

Code comment of [simple-app](examples/simple-app/flake.nix) shows how to use ruby_3_1 instead of the
_current_ default version (2.7.6). You can also write your own overlay that overrides globally with your own ruby derivation.

## Common issues

#### I want to use a custom ruby version
Check the [sample](examples/simple-app/flake.nix). @bobvanderlinden maintains it at the [nixpkgs-ruby](https://github.com/bobvanderlinden/nixpkgs-ruby/tree/master) project.

#### Local bundle config overriding environment
Check your `.bundle/config` 

#### Ruby or gems don't come from nix
Check that you have removed `.rbenv` or `.rvm`

#### Bundle install doesn't work
Check the previous section. You should only use `bundler` to lock your dependencies, not install them.

#### I don't like that `nix develop` is a bash shell
Use `nix develop -c zsh` or even better install `.envrc`, following this guide.

## Roadmap

1. Try out more ruby versions, both old and new
2. Make bundix runs faster
3. More documentations

## Credits

All credits goes to the original authors of `buildRubyGem`, `bundlerEnv`, and `bundix` (@manveru, @lavoiesl, @jdelStrother). This is only a thin layer with a different take on top of these solid foundation. 

PRs welcomed :)
