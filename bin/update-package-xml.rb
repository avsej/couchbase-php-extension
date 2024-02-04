#!/usr/bin/env ruby

require "nokogiri"

project_root = File.expand_path(File.join(__dir__, ".."))
package_xml_path = File.join(project_root, "package.xml")
package_xml = Nokogiri::XML.parse(File.read(package_xml_path)) { |x| x.noblanks }

files = [
    "LICENSE",
    "Makefile.frag",
    "config.m4",
    "config.w32",
#    "Couchbase/**/*.php", Revert this once we choose to package PS
    "Couchbase/*.php",
    "Couchbase/Datastructures/**/*.php",
    "Couchbase/Exception/*.php",
    "Couchbase/Management/*.php",
    "Couchbase/Utilities/*.php",
    "src/*.{cxx,hxx}",
    "src/CMakeLists.txt",
    "src/cmake/**/*",
    "src/deps/couchbase-cxx-client/CMakeLists.txt",
    "src/deps/couchbase-cxx-client/LICENSE.txt",
    "src/deps/couchbase-cxx-client/cmake/*",
    "src/deps/couchbase-cxx-client/core/**/*",
    "src/deps/couchbase-cxx-client/couchbase/**/*",
    "src/deps/couchbase-cxx-client/third_party/expected/COPYING",
    "src/deps/couchbase-cxx-client/third_party/expected/include/**/*.hpp",
    "src/deps/couchbase-cxx-client/third_party/jsonsl/*",
    "src/wrapper/**/*.{cxx,hxx}",
].map do |glob|
  Dir.chdir(project_root) do
    Dir.glob(glob, File::FNM_DOTMATCH).select { |path| File.file?(path) }
  end
end.flatten

tree = {directories: {}, files: []}
files.sort.uniq.each do |file|
  parts = file.split("/")
  parents = parts[0..-2]
  filename = parts[-1]
  cursor = tree
  parents.each do |parent|
    cursor[:directories][parent] ||= {directories: {}, files: []}
    cursor = cursor[:directories][parent]
  end
  role =
    case filename
    when /\.php$/
      "php"
    when /README|LICENSE|COPYING/
      "doc"
    else
      "src"
    end
  role = "src" if filename == "README.rst" && parents.last == "fmt"
  cursor[:files] << {name: filename, role: role}
end

def traverse(document, reader, writer)
  reader[:directories].each do |name, dir|
    node = document.create_element("dir")
    node["name"] = name
    writer.add_child(node)
    traverse(document, dir, node)
  end
  reader[:files].each do |file|
    node = document.create_element("file")
    node["role"] = file[:role]
    node["name"] = file[:name]
    writer.add_child(node)
  end
end

root = package_xml.create_element("dir")
root["name"] = "/"
traverse(package_xml, tree, root)

package_xml.at_css("package contents").children = root
File.write(package_xml_path, package_xml.to_xml(indent: 4))
