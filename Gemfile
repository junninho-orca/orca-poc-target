source "https://rubygems.org"

# Runtime dependency of the delivery endpoint.
gem "rack", "3.0.9.1"

# The test runner lives here rather than in a separate group on purpose: the sandbox installs
# from this file and then runs the suite in a second, offline container, so anything the tests
# need has to come from here — the same reason jest sits in package.json's devDependencies.
gem "rake", "13.2.1"
gem "minitest", "5.24.1"
