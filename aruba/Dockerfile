FROM ruby
MAINTAINER Venafi DevOps Integrations <opensource@venafi.com>

RUN gem install aruba json_spec
COPY . /vcert/

# Optional: copy Isara OpenSSL (located in the isara folder)
# If the folder does not exist, it will just copy the README file.
COPY README isara*/usr /usr/
COPY README isara*/Toolkit /Toolkit/

# Assume that Isara OpenSSL is installed under /usr/local/isara_ssl
# Change the path below if this is not the case.
ENV PATH="/vcert/bin:${PATH}:/usr/local/isara_ssl/bin"

WORKDIR /vcert/
CMD ["cucumber", "--no-color"]
