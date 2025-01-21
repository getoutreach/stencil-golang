APP := stencil-golang
OSS := false
_ := $(shell ./scripts/devbase.sh)

include .bootstrap/root/Makefile

## <<Stencil::Block(targets)>>
post-stencil::
	./scripts/shell-wrapper.sh catalog-sync.sh
	make fmt
	yarn upgrade

pre-fmt::
	./scripts/sync-gomod.sh
	@pushd ./pkg && go mod tidy; popd
## <</Stencil::Block>>
