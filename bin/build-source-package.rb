#!/usr/bin/env ruby

require "fileutils"
require "tempfile"
require "open3"
require "rubygems/package"

class Object
  def to_b
    ![nil, false, 0, "", "0", "f", "F", "false", "FALSE", "off", "OFF", "no", "NO"].include?(self)
  end
end

def run(*args)
  args = args.compact.map(&:to_s)
  puts args.join(" ")
  system(*args) || abort("command returned non-zero status: #{args.join(" ")}")
end

def which(name, extra_locations = [])
  ENV.fetch("PATH", "")
     .split(File::PATH_SEPARATOR)
     .prepend(*extra_locations)
     .select { |path| File.directory?(path) }
     .map { |path| [path, name].join(File::SEPARATOR) + RbConfig::CONFIG["EXEEXT"] }
     .find { |file| File.executable?(file) }
end

def supports_flag?(command, flag)
  out, _, status = Open3.capture3(command, "--help")
  out.include?(flag)
end

project_root = File.expand_path(File.join(__dir__, ".."))
cxx_core_root = File.join(project_root, "src", "deps", "couchbase-cxx-client")

puts("-----> record code revisions")
library_revision = Dir.chdir(project_root) { `git rev-parse HEAD`.strip }
core_revision = Dir.chdir(cxx_core_root) { `git rev-parse HEAD`.strip }
core_describe = Dir.chdir(cxx_core_root) { `git describe --long --always HEAD`.strip }

output_dir = Dir.mktmpdir("cxx_output_")
output_tarball = File.join(output_dir, "cache.tar")
cpm_cache_dir = Dir.mktmpdir("cxx_cache_")
cxx_core_build_dir =  Dir.mktmpdir("cxx_build_")
cxx_core_source_dir = File.join(project_root, "src", "deps", "couchbase-cxx-client")
cc = ENV.fetch("CB_CC", nil)
cxx = ENV.fetch("CB_CXX", nil)
ar = ENV.fetch("CB_AR", nil)

cmake_extra_locations = []
if RUBY_PLATFORM.match?(/mswin|mingw/)
  cmake_extra_locations = [
    'C:\Program Files\CMake\bin',
    'C:\Program Files\Microsoft Visual Studio\2022\Professional\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin',
    'C:\Program Files\Microsoft Visual Studio\2019\Professional\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin',
  ]
  local_app_data = ENV.fetch("LOCALAPPDATA", "#{Dir.home}\\AppData\\Local")
  cmake_extra_locations.unshift("#{local_app_data}\\CMake\\bin") if File.directory?(local_app_data)
end
cmake = which("cmake", cmake_extra_locations) || which("cmake3", cmake_extra_locations)
cmake_flags = [
  "-S#{cxx_core_source_dir}",
  "-B#{cxx_core_build_dir}",
  "-DCOUCHBASE_CXX_CLIENT_BUILD_TESTS=OFF",
  "-DCOUCHBASE_CXX_CLIENT_BUILD_TOOLS=OFF",
  "-DCOUCHBASE_CXX_CLIENT_BUILD_DOCS=OFF",
  "-DCOUCHBASE_CXX_CLIENT_STATIC_BORINGSSL=ON",
  "-DCPM_DOWNLOAD_ALL=ON",
  "-DCPM_USE_NAMED_CACHE_DIRECTORIES=ON",
  "-DCPM_USE_LOCAL_PACKAGES=OFF",
  "-DCPM_SOURCE_CACHE=#{cpm_cache_dir}",
]
cmake_flags << "-DCMAKE_C_COMPILER=#{cc}" if cc
cmake_flags << "-DCMAKE_CXX_COMPILER=#{cxx}" if cxx
cmake_flags << "-DCMAKE_AR=#{ar}" if ar

puts("-----> run cmake to dowload all depenencies (#{cmake})")
run(cmake, *cmake_flags)

puts("-----> create archive with whitelisted sources: #{output_tarball}")
File.open(output_tarball, "w+b") do |file|
  Gem::Package::TarWriter.new(file) do |writer|
    Dir.chdir(cxx_core_build_dir) do
      ["mozilla-ca-bundle.sha256", "mozilla-ca-bundle.crt"].each do |path|
        writer.add_file(path, 0o660) { |io| io.write(File.binread(path)) }
      end
    end
    Dir.chdir(cpm_cache_dir) do
      third_party_sources = Dir[
        "cpm/*.cmake",
        "asio/*/LICENSE*",
        "asio/*/asio/COPYING",
        "asio/*/asio/asio/include/*.hpp",
        "asio/*/asio/asio/include/asio/**/*.[hi]pp",
        "boringssl/*/boringssl/**/*.{cc,h,c,asm,S}",
        "boringssl/*/boringssl/**/CMakeLists.txt",
        "boringssl/*/boringssl/LICENSE",
        "fmt/*/fmt/CMakeLists.txt",
        "fmt/*/fmt/ChangeLog.rst",
        "fmt/*/fmt/LICENSE.rst",
        "fmt/*/fmt/README.rst",
        "fmt/*/fmt/include/**/*",
        "fmt/*/fmt/src/**/*",
        "fmt/*/fmt/support/cmake/**/*",
        "gsl/*/gsl/CMakeLists.txt",
        "gsl/*/gsl/GSL.natvis",
        "gsl/*/gsl/LICENSE*",
        "gsl/*/gsl/ThirdPartyNotices.txt",
        "gsl/*/gsl/cmake/*",
        "gsl/*/gsl/include/**/*",
        "hdr_histogram/*/hdr_histogram/*.pc.in",
        "hdr_histogram/*/hdr_histogram/CMakeLists.txt",
        "hdr_histogram/*/hdr_histogram/COPYING.txt",
        "hdr_histogram/*/hdr_histogram/LICENSE.txt",
        "hdr_histogram/*/hdr_histogram/cmake/*",
        "hdr_histogram/*/hdr_histogram/config.cmake.in",
        "hdr_histogram/*/hdr_histogram/include/**/*",
        "hdr_histogram/*/hdr_histogram/src/**/*",
        "json/*/json/CMakeLists.txt",
        "json/*/json/LICENSE*",
        "json/*/json/external/PEGTL/.cmake/*",
        "json/*/json/external/PEGTL/CMakeLists.txt",
        "json/*/json/external/PEGTL/LICENSE*",
        "json/*/json/external/PEGTL/include/**/*",
        "json/*/json/include/**/*",
        "llhttp/*/llhttp/*.pc.in",
        "llhttp/*/llhttp/CMakeLists.txt",
        "llhttp/*/llhttp/LICENSE*",
        "llhttp/*/llhttp/include/*.h",
        "llhttp/*/llhttp/src/*.c",
        "snappy/*/snappy/CMakeLists.txt",
        "snappy/*/snappy/COPYING",
        "snappy/*/snappy/cmake/*",
        "snappy/*/snappy/snappy-c.{h,cc}",
        "snappy/*/snappy/snappy-internal.h",
        "snappy/*/snappy/snappy-sinksource.{h,cc}",
        "snappy/*/snappy/snappy-stubs-internal.{h,cc}",
        "snappy/*/snappy/snappy-stubs-public.h.in",
        "snappy/*/snappy/snappy.{h,cc}",
        "spdlog/*/spdlog/CMakeLists.txt",
        "spdlog/*/spdlog/LICENSE",
        "spdlog/*/spdlog/cmake/*",
        "spdlog/*/spdlog/include/**/*",
        "spdlog/*/spdlog/src/**/*",
      ].grep_v(/crypto_test_data.cc/)

      # we don't want to fail if git is not available
      cpm_cmake_path = third_party_sources.grep(/cpm.*\.cmake$/).first
      File.write(cpm_cmake_path, File.read(cpm_cmake_path).gsub("Git REQUIRED", "Git"))

      third_party_sources
        .select { |path| File.file?(path) }
        .each { |path| writer.add_file(path, 0o660) { |io| io.write(File.binread(path)) } }
    end
  end
end

FileUtils.rm_rf(cxx_core_build_dir, verbose: true)
FileUtils.rm_rf(cpm_cache_dir, verbose: true)

tar = which("tar")
untar = [tar, "-x"]
untar << "--force-local" if supports_flag?(tar, "--force-local")

puts("-----> verify that tarball works as a cache for CPM")
cxx_core_build_dir = Dir.mktmpdir("cxx_build_")
cpm_cache_dir = Dir.mktmpdir("cxx_cache_")
Dir.chdir(cpm_cache_dir) do
  run(*untar, "-f", output_tarball)
end

cmake_flags = [
  "-S#{cxx_core_source_dir}",
  "-B#{cxx_core_build_dir}",
  "-DCOUCHBASE_CXX_CLIENT_BUILD_TESTS=OFF",
  "-DCOUCHBASE_CXX_CLIENT_BUILD_TOOLS=OFF",
  "-DCOUCHBASE_CXX_CLIENT_BUILD_DOCS=OFF",
  "-DCOUCHBASE_CXX_CLIENT_STATIC_BORINGSSL=ON",
  "-DCPM_DOWNLOAD_ALL=OFF",
  "-DCPM_USE_NAMED_CACHE_DIRECTORIES=ON",
  "-DCPM_USE_LOCAL_PACKAGES=OFF",
  "-DCPM_SOURCE_CACHE=#{cpm_cache_dir}",
  "-DCOUCHBASE_CXX_CLIENT_EMBED_MOZILLA_CA_BUNDLE_ROOT=#{cpm_cache_dir}",
]
cmake_flags << "-DCMAKE_C_COMPILER=#{cc}" if cc
cmake_flags << "-DCMAKE_CXX_COMPILER=#{cxx}" if cxx
cmake_flags << "-DCMAKE_AR=#{ar}" if ar

run(cmake, *cmake_flags)

FileUtils.rm_rf(cxx_core_build_dir, verbose: true)
FileUtils.rm_rf(cpm_cache_dir, verbose: true)

cache_dir = File.join(project_root, "src", "cmake", "cache")
FileUtils.rm_rf(cache_dir, verbose: true)
abort("unable to remove #{cache_dir}") if File.directory?(cache_dir)
FileUtils.mkdir_p(cache_dir, verbose: true)
Dir.chdir(cache_dir) do
  run(*untar, "-f", output_tarball)
end
FileUtils.rm_rf(output_dir, verbose: true)

File.write(File.join(project_root, "src", "cmake", "extra.cmake"), <<~EXTRA)
  set(EXT_GIT_REVISION #{library_revision.inspect})
  set(COUCHBASE_CXX_CLIENT_GIT_REVISION #{core_revision.inspect})
  set(COUCHBASE_CXX_CLIENT_GIT_DESCRIBE #{core_describe.inspect})
  set(CPM_DOWNLOAD_ALL OFF)
  set(CPM_USE_NAMED_CACHE_DIRECTORIES ON)
  set(CPM_USE_LOCAL_PACKAGES OFF)
  set(CPM_SOURCE_CACHE ${PROJECT_SOURCE_DIR}/cmake/cache)
  set(COUCHBASE_CXX_CLIENT_EMBED_MOZILLA_CA_BUNDLE_ROOT ${PROJECT_SOURCE_DIR}/cmake/cache)
EXTRA

package_xml_path = File.join(project_root, "package.xml")
File.write(
  package_xml_path,
  File
    .read(package_xml_path)
    .gsub(/^ {4}<date>.*<\/date>$/, "    <date>#{Time.now.strftime("%Y-%m-%d")}</date>")
)

ruby = ENV.fetch("CB_RUBY_PATH", "ruby")
run(ruby, File.join(project_root, "bin", "update-package-xml.rb"))

Dir.chdir(project_root) do
  FileUtils.rm_rf("couchbase-*.tgz")
  pecl = ENV.fetch("CB_PECL_PATH", "pecl")
  run(pecl, "package")

  main_header = File.read(File.join(project_root, "src/php_couchbase.hxx"))
  sdk_version = main_header[/PHP_COUCHBASE_VERSION "(\d+\.\d+\.\d+)"/, 1]
  snapshot = ENV.fetch("BUILD_NUMBER", 0) unless ENV.fetch("IS_RELEASE", false).to_b
  package_version = "#{sdk_version}.#{snapshot}"
  package_filename = "couchbase-#{package_version}.tgz"
  if snapshot
    FileUtils.mv("couchbase-#{sdk_version}.tgz", package_filename, verbose: true)
  end
  File.write("PACKAGE_VERSION", package_version)
  File.write("PACKAGE_FILENAME", package_filename)
end
