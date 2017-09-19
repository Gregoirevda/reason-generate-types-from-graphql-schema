PREFIX?=$(shell opam config var prefix)

build:
	ocamlbuild -use-ocamlfind  src/index.native

install: build
	@opam-installer --prefix=$(PREFIX) reason-generate-types-from-graphql-schema.install

uninstall:
	@opam-installer -u --prefix=$(PREFIX) reason-generate-types-from-graphql-schema.install

clean:
	rm -rf _build index.native

.PHONY: build clean