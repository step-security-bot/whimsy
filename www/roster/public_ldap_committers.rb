# Creates JSON output with the following format:
#
# {
#   "last_updated": "2016-01-20 00:47:45 UTC",
#   "git_info": "9d1cefc  2016-01-22T11:44:14+00:00",
#   "committers": { // committers who have valid login shells
#     "uid": "Public Name",
#     ...
#   },
#   "committers_nologin": { // committers with invalid login shells
#     "uid": "Public Name",
#     ...
#   },
#   "non_committers": { // entries in 'ou=people,dc=apache,dc=org' who are not committers
#     "uid": "Public Name",
#     ...
# }
#

require 'bundler/setup'

require 'whimsy/asf'

GITINFO = ASF.library_gitinfo rescue '?'

# parse arguments for output file name
if ARGV.length == 0 or ARGV.first == '-'
  output = STDOUT
else
  output = File.open(ARGV.first, 'w')
end

ldap = ASF.init_ldap
exit 1 unless ldap

# gather committer info
ids = {}
# banned or deceased or emeritus or ...
ban = {}
# people entries that are not committers (and not in nologin)
non = {}

peeps = ASF::Person.preload('loginShell',{}) # needed for the banned? method

ASF.committers.sort_by {|a| a.id}.each do |entry|
    if entry.banned?
        ban[entry.id] = entry.public_name 
    else
        ids[entry.id] = entry.public_name 
    end
end

peeps.sort_by {|a| a.name}.each do |e|
  if ASF.committers.include? e
  else
      non[e.name] = e.public_name
  end
end

info = {
  last_updated: ASF::ICLA.svn_change,
  git_info: GITINFO,
  committers: ids,
  committers_nologin: ban,
  non_committers: non,
}

# output results
output.puts JSON.pretty_generate(info)
output.close
