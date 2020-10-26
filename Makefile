GOFLAGS ?= $(GOFLAGS:)

ifdef BUILD_NUMBER
VERSION=`git describe --abbrev=0 --tags`+$(BUILD_NUMBER)
else
VERSION=`git describe --abbrev=0 --tags`
endif


#define version if release is set
ifdef RELEASE_VERSION
ifdef BUILD_NUMBER
VERSION=$(RELEASE_VERSION)+$(BUILD_NUMBER)
else
VERSION=$(RELEASE_VERSION)
endif
endif

CGO_ENABLED_LINUX_X64=0
CGO_ENABLED_DARWIN_X64=0
CGO_ENABLED_WIN_X64=0

ifdef IQR_TOOLKIT_PATH_LINUX_X64
$(info *******************************************************)
$(info *       Build with Iqr toolkit Linux x64              *)
$(info *******************************************************)
LD_LINUX_X64=$(IQR_TOOLKIT_PATH_LINUX_X64)/lib_x86_64/libiqr_toolkit.a
CGO_ENABLED_LINUX_X64=1
export CGO_CPPFLAGS=-I$(IQR_TOOLKIT_PATH_LINUX_X64)
export CGO_ENABLED=1
export CGO_LDFLAGS=$(LD_LINUX_X64)
endif

ifdef IQR_TOOLKIT_PATH_DARWIN_X64
$(info *********************************************************)
$(info *       Build with Iqr toolkit Darwin x64               *)
$(info *********************************************************)
LD_DARWIN_X64=$(IQR_TOOLKIT_PATH_DARWIN_X64)/lib_x86_64/libiqr_toolkit.a
CGO_ENABLED_DARWIN_X64=1
export CGO_CPPFLAGS=-I$(IQR_TOOLKIT_PATH_DARWIN_X64)
export CGO_ENABLED=1
endif

ifdef IQR_TOOLKIT_PATH_WIN_X64
$(info *********************************************************)
$(info *       Build with Iqr toolkit Windows x64              *)
$(info *********************************************************)
LD_WIN_X64=$(IQR_TOOLKIT_PATH_WIN_X64)/lib_x86_64/libiqr_toolkit_static.lib
CGO_ENABLED_WIN_X64=1
export CGO_CPPFLAGS=-I$(IQR_TOOLKIT_PATH_WIN_X64)
export CGO_ENABLED=1
#Enable the following line if "make test" with IQR toolkit is run on Windows.
#export CGO_LDFLAGS=$(LD_WIN_X64)
endif

ifneq ($(CGO_ENABLED), 1)
$(info *************************************************)
$(info *           Build without Iqr toolkit           *)
$(info *************************************************)
export CGO_ENABLED=0
CGO_ENABLED_LINUX_X64=0
CGO_ENABLED_DARWIN_X64=0
CGO_ENABLED_WIN_X64=0
endif

export CGO_LDFLAGS_TEST=$(LD_WIN_X64)
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Linux)
	export CGO_LDFLAGS_TEST=$(LD_LINUX_X64)
endif
ifeq ($(UNAME_S),Darwin)
	export CGO_LDFLAGS_TEST=$(LD_DARWIN_X64)
endif

GO_LDFLAGS=-ldflags "-X github.com/Venafi/vcert.versionString=$(VERSION) -X github.com/Venafi/vcert.versionBuildTimeStamp=`date -u +%Y%m%d.%H%M%S` -s -w"
version:
	echo "$(VERSION)"

get: gofmt
	env CGO_ENABLED=0 go get $(GOFLAGS) ./...

build_quick: get
	env GOOS=linux GOARCH=amd64 CGO_ENABLED=$(CGO_ENABLED_LINUX_X64) CGO_LDFLAGS=$(LD_LINUX_X64) go build $(GO_LDFLAGS) -o bin/linux/vcert         ./cmd/vcert
	mkdir -p aruba/bin
	cp bin/linux/vcert aruba/bin/vcert

build_quick_win64: get
	env GOOS=windows GOARCH=amd64 CGO_ENABLED=$(CGO_ENABLED_WIN_X64) CGO_LDFLAGS=$(LD_WIN_X64) CXX=x86_64-w64-mingw32-g++ CC=x86_64-w64-mingw32-gcc go build $(GO_LDFLAGS) -o bin/windows/vcert.exe   ./cmd/vcert
	mkdir -p aruba/bin
	cp bin/windows/vcert.exe aruba/bin/vcert.exe

build: get
	env GOOS=linux   GOARCH=amd64 CGO_ENABLED=$(CGO_ENABLED_LINUX_X64)  CGO_LDFLAGS=$(LD_LINUX_X64)  go build $(GO_LDFLAGS) -o bin/linux/vcert         ./cmd/vcert
	env GOOS=linux   GOARCH=386   CGO_ENABLED=0 go build $(GO_LDFLAGS) -o bin/linux/vcert86       ./cmd/vcert
	env GOOS=darwin  GOARCH=amd64 CGO_ENABLED=$(CGO_ENABLED_DARWIN_X64) CGO_LDFLAGS=$(LD_DARWIN_X64) go build $(GO_LDFLAGS) -o bin/darwin/vcert        ./cmd/vcert
	#env GOOS=darwin  GOARCH=386   CGO_ENABLED=0 go build $(GO_LDFLAGS) -o bin/darwin/vcert86      ./cmd/vcert
	env GOOS=windows GOARCH=amd64 CGO_ENABLED=$(CGO_ENABLED_WIN_X64)    CGO_LDFLAGS=$(LD_WIN_X64)    CXX=x86_64-w64-mingw32-g++ CC=x86_64-w64-mingw32-gcc go build $(GO_LDFLAGS) -o bin/windows/vcert.exe   ./cmd/vcert
	env  GOOS=windows GOARCH=386   CGO_ENABLED=0 go build $(GO_LDFLAGS) -o bin/windows/vcert86.exe ./cmd/vcert

cucumber:
	rm -rf ./aruba/bin/
	mkdir -p ./aruba/bin/ && cp ./bin/linux/vcert ./aruba/bin/vcert
	docker build --tag vcert.auto aruba/
	if [ -z "$(FEATURE)" ]; then \
		cd aruba && ./cucumber.sh; \
	else \
		cd aruba && ./cucumber.sh $(FEATURE); \
	fi

gofmt:
	! gofmt -l . | grep -v ^vendor/ | grep .

test: get linter
	env CGO_LDFLAGS=$(CGO_LDFLAGS_TEST) go test -v -cover .
	env CGO_LDFLAGS=$(CGO_LDFLAGS_TEST) go test -v -cover ./pkg/certificate
	env CGO_LDFLAGS=$(CGO_LDFLAGS_TEST) go test -v -cover ./pkg/endpoint
	env CGO_LDFLAGS=$(CGO_LDFLAGS_TEST) go test -v -cover ./pkg/venafi/fake
	env CGO_LDFLAGS=$(CGO_LDFLAGS_TEST) go test -v -cover ./cmd/vcert

tpp_test: get
	env CGO_LDFLAGS=$(CGO_LDFLAGS_TEST) go test -v $(GOFLAGS) ./pkg/venafi/tpp

cloud_test: get
	env CGO_LDFLAGS=$(CGO_LDFLAGS_TEST) go test -v $(GOFLAGS) ./pkg/venafi/cloud

collect_artifacts:
	rm -rf artifcats
	mkdir -p artifcats
	VERSION=`git describe --abbrev=0 --tags`
	mv bin/linux/vcert artifcats/vcert-$(VERSION)_linux
	mv bin/linux/vcert86 artifcats/vcert-$(VERSION)_linux86
	mv bin/darwin/vcert artifcats/vcert-$(VERSION)_darwin
	mv bin/windows/vcert.exe artifcats/vcert-$(VERSION)_windows.exe
	mv bin/windows/vcert86.exe artifcats/vcert-$(VERSION)_windows86.exe
	cd artifcats; echo '```' > ../release.txt
	cd artifcats; sha1sum * >> ../release.txt
	cd artifcats; echo '```' >> ../release.txt

release:
	go get -u github.com/tcnksm/ghr
	ghr -prerelease -n $$RELEASE_VERSION -body="$$(cat ./release.txt)" $$RELEASE_VERSION artifcats/
linter:
	env CGO_ENABLED=0 golangci-lint run
