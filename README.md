
# OpenArena Legacy for Apple Silicon.

I want to preface by saying this port/recompilation is simply because I wish to play the game on my laptop.
I grew up playing OpenArena, back then it was on a 32 bit laptop running ubuntu 8.04. Back then I didn't even have a mouse, so I got decent with the trackpad.

Coding agents are being used on this endeavor and I make no claim in terms of skill or talent when it comes to this codebase.
This is simply me solving a problem and satisfying a need.

No modifications to assets or art will be made. Any modification to game code is for the express purpose of making it compile and run on M1 and above chips. 

Controller/gamepad support may be added.

For now I will ad hoc sign.

## Install via Homebrew

```sh
brew tap AJ-Gonzalez/openarena https://github.com/AJ-Gonzalez/openarena-silicon-legacy.git
brew install --HEAD AJ-Gonzalez/openarena/openarena
```

This builds the engine and game code and installs `OpenArena.app` with the
official 0.8.8 game data (pinned and checksum-verified). Launch it with
`open "$(brew --prefix)/opt/openarena/OpenArena.app"` or run `openarena`.

## Build instructions

One command:

```sh
./build.sh
```

It checks the dependencies, builds the engine and game code, downloads the
official 0.8.8 game data (checksum-verified), assembles `OpenArena.app`, and
installs it to `/Applications`.

Dependencies:

* macOS on Apple Silicon (arm64)
* [Homebrew](https://brew.sh)
* Xcode Command Line Tools (`xcode-select --install`)
* Homebrew packages: `sdl12-compat`, `libogg`, `libvorbis`
  (`build.sh` installs these if they are missing)

## OpenArena Legacy Repository

Legacy source code releases from [OpenArena](http://openarena.ws).
The game data is still in OpenArena's SVN repository hosted on the site itself.

This is an archive of the OpenArena 0.8.8 release code.  No new development
happens here.

The current development of OpenArena code happens in two places

* [engine.git](https://github.com/OpenArena/engine.git) project for the new
engine, and
* [gamecode.git](https://github.com/OpenArena/gamecode.git) for the new game code.

## Checksums ##

Checksums and locations for the original code:

* [OA game code](http://files.poulsander.com/~poul19/public_files/oa/dev088/oa-0.8.8.tar.bz2)
* [OA engine](http://files.poulsander.com/~poul19/public_files/oa/dev088/openarena-engine-source-0.8.8.tar.bz2)

```sh
$ md5sum *.bz2
5a55bb7660a711949a69a2bc40fdc11b  oa-0.8.8.tar.bz2
ca9b239b477ad678ebf781e14ce6ed7a  openarena-engine-source-0.8.8.tar.bz2

$ sha1sum *.bz2
6bb139e469ae00e37decaefb5e2bced070f8b04e  oa-0.8.8.tar.bz2
64f333c290b15b6b0e3819dc120b3eca2653340e  openarena-engine-source-0.8.8.tar.bz2

$ sha512sum *.bz2
517517ea8d8377a6d91d957faf0a55690815b01d8f3e8b1e4a3e6be64750968a6074d26499e707fe2ec5fa7d630ceec022fdc879fdebcbfebbcff8195dd03e2f  oa-0.8.8.tar.bz2
d4ba3655fae500cf5b7475c83d39c81b6abc759da15cfb4ea9e1dc0f47ffb11c1bbbc2b6f85d613ab1d729978eda93d4d7677c9a45a33853e363c820d8b81c43  openarena-engine-source-0.8.8.tar.bz2
```
