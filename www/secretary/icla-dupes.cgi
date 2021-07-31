#!/usr/bin/env ruby

# script to try and find duplicate ICLAs from the same people

$LOAD_PATH.unshift '/srv/whimsy/lib'

require 'wunderbar/script'
require 'ruby2js/filter/functions'
require 'whimsy/asf'

_html do
  _style %{
    table {border-collapse: collapse}
    table, th, td {border: 1px solid black}
    td {padding: 3px 6px}
    tr:hover td {background-color: #FF8}
    th {background-color: #a0ddf0}
  }

  _h1 'ICLA duplicates check'

  _p do
    _ 'This script checks for possible duplicate ICLAs.'
    _ 'It does this by splitting the Full Names into separate words, sorting them and then looking for duplicates.'
  end

  _p 'Further checks TBA, e.g. looking for partial matches'

  dups = Hash.new{|h,k| h[k]=Array.new}
  ASF::ICLA.each do |icla|
    legal=icla.legal_name
    key = legal.split(' ').sort.join(' ')
    dups[key] << {legal: legal, email: icla.email, claRef: icla.claRef, id: icla.id}
  end

  _table do
    _tr do
      _th 'Key'
      _th 'Id'
      _th 'Legal Name'
      _th 'Email'
      _th 'CLAref'
    end
    dups.sort_by{|k,v| k}.each do |key, val|
      if val.size > 1
        _tr do
          _td key
          _td do
            val.each do |v|
              id = v[:id]
              if id == 'notinavail'
                _ id
              else
                _a id, href: '/roster/committer/' + id
              end
              _br
            end
          end
          _td do
            val.each do |v|
              _ v[:legal]
              _br
            end
          end
          _td do
            val.each do |v|
              _ v[:email]
              _br
            end
          end
          _td do
            val.each do |v|
              claRef = v[:claRef]
              file = ASF::ICLAFiles.match_claRef(claRef)
              if file
                _a claRef, href: ASF::SVN.svnpath!('iclas', file)
              else
                _ claRef
              end
              _br
            end
          end
        end
      end
    end  
  end
end
