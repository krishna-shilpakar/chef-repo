#
# Cookbook Name:: mongodb
# Recipe:: install
#
# Copyright 2010, CustomInk, LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

group node[:mongodb][:group] do
  action [ :create, :manage ]
end


user node[:mongodb][:user] do
  comment "MongoDB Server"
  gid node[:mongodb][:group]
  action [ :create, :manage ]
end

case node[:platform]
when "centos","redhat","fedora","suse"
  # use the 10gen repo
  include_recipe "mongodb::10gen_repo"
  package "mongo-10gen-server"
when "debian","ubuntu"
  # installing from package
  bash "adding mongodb 10gen to /etc/apt/sources.list" do
    user "root"
    code <<-EOH
    echo "deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen" >> /etc/apt/sources.list
    apt-key adv --keyserver keyserver.ubuntu.com --recv 7F0CEB10
    apt-get update
    EOH
    only_if do
      result = File.open("/etc/apt/sources.list").grep(/^deb http:\/\/downloads-distro.mongodb.org/)
      result.empty?
    end 
  end

  bash "installing_mongodb" do
    user "root"
    code <<-EOH
    apt-get install mongodb-10gen
    EOH
    not_if do
      File.exist?(node[:mongodb][:binaries] + "/mongod")
    end
  end
  
  
  # if !(::File.exists?("/tmp/#{node[:mongodb][:file_name]}.tgz"))
  #   Chef::Log.info "Downloading MongoDB (#{node[:mongodb][:file_name]}.tgz) from #{node[:mongodb][:url]}. This could take a while..."
  #   remote_file "/tmp/#{node[:mongodb][:file_name]}.tgz" do
  #     source node[:mongodb][:url]
  #     not_if { ::File.exists?("/tmp/#{node[:mongodb][:file_name]}.tgz") }
  #   end
  # end
  # 
  # bash "install-mongodb" do
  #   cwd "/tmp"
  #   code <<-EOH
  #   tar zxvf #{node[:mongodb][:file_name]}.tgz
  #   mkdir -p #{node[:mongodb][:binaries]}
  #   mv #{node[:mongodb][:file_name]}/bin/* #{node[:mongodb][:binaries]}
  #   chmod 755 #{node[:mongodb][:binaries]}
  #   EOH
  #   not_if { ::File.exists?("#{node[:mongodb][:binaries]}/mongod") && `mongo --version` != "MongoDB shell version: #{node[:mongodb][:version]}"}
  #   # not_if { ::File.exists?("#{node[:mongodb][:binaries]}/mongod") }
  # end
end

# Add bin directory to everyone's path for bash
template "/etc/profile.d/mongodb.sh" do
  source "mongo.sh.erb"
  owner "root"
  group "root"
  mode 0755
end

# Add bin directory to everyone's path for csh
template "/etc/profile.d/mongodb.csh" do
  source "mongo.csh.erb"
  owner "root"
  group "root"
  mode 0755
end
