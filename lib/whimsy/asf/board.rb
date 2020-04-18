require_relative '../asf'
require 'tzinfo'

module ASF
  module Board
    TIMEZONE = ActiveSupport::TimeZone.new('UTC')

    # sorted list of Directors
    # default to names only
    # if withId == true, then return hash: { id: {name: public_name}}
    # This allows for returning additional data such as start of tenure
    # sort is by last name
    def self.directors(withId=false)
      if withId
        ASF::Service['board'].members.
        map {|person| [person.id, {name: person.public_name}]}.
          sort_by {|id,hash| hash[:name].split(' ').rotate(-1)}.to_h
      else
        ASF::Service['board'].members.
          map {|person| person.public_name}.
            sort_by {|name| name.split(' ').rotate(-1)}
      end
    end

    # list of board meeting times as listed in 
    # committers/board/calendar.txt
    def self.calendar
      svn = ASF::SVN.find('board')
      return [] unless svn
      txt = File.read(File.join(svn, 'calendar.txt'))
      times = txt.scan(/^\s+\*\)\s(.*)/).flatten
      times.map {|time| TIMEZONE.parse(time)}
    end

    # time of next meeting
    def self.nextMeeting
      time = self.calendar.select {|time| time > Time.now.utc}.min

      if not time
        require 'chronic'
        this_month = Time.now.strftime('%B')

        time = Chronic.parse("3rd wednesday in #{this_month}")

        if not time or time < Time.now.utc
          time = Chronic.parse('3rd wednesday next month')
        end

        time = TIMEZONE.Time.parse("#{time.to_date} 21:30")
      end

      time
    end

    # time of previous meeting
    def self.lastMeeting
      next_meeting = self.nextMeeting
      time = self.calendar.select {|time| time < next_meeting}.max

      if not time
        require 'chronic'
        this_month = Time.now.strftime('%B')

        time ||= Chronic.parse("3rd wednesday in #{this_month}")

        if not time or time > Time.now.utc
          time = Chronic.parse('3rd wednesday last month')
        end

        time = TIMEZONE.Time.parse("#{time.to_date} 21:30")
      end

      time
    end

    # list of PMCs reporting in the specified meeting
    def self.reporting(meeting)
      month = meeting.strftime('%B')
      ASF::Committee.load_committee_info
      ASF::Committee.pmcs.select do |pmc| 
        pmc.report.split(', ').include? month or pmc.report == 'Every month' or
        pmc.report.start_with? 'Next month'
      end
    end

    # source for shepherd information, yields a stream of director names
    # in random order
    class ShepherdStream < Enumerator
      def initialize
        @directors = ASF::Service['board'].members

        super do |generator|
          list = []
          loop do
            list = @directors.shuffle if list.empty?
            victim = list.pop
            firstname = ASF::Board.directorFirstName(victim.id) || 
              victim.public_name.split(' ').first
            generator.yield firstname
          end
        end
      end

      def for(pmc)
        chair = pmc.chair

        if @directors.include? chair
          "#{chair.public_name}"
        else
          "#{chair.public_name} / #{self.next}"
        end
      end
    end

    # Does the uid have an entry in the director intials table?
    def self.directorHasId?(id)
      DIRECTOR_MAP[id]
    end 

    # Return the initials for the uid
    # Fails if there is no entry, so check first using directorHasId?
    def self.directorInitials(id)
      DIRECTOR_MAP[id] && DIRECTOR_MAP[id][INITIALS]
    end 
    
    # Return the first name for the uid
    # Fails if there is no entry, so check first using directorHasId?
    def self.directorFirstName(id)
      DIRECTOR_MAP[id] && DIRECTOR_MAP[id][FIRST_NAME]
    end

    # Return the display name for the uid
    # Fails if there is no entry, so check first using directorHasId?
    def self.directorDisplayName(id)
      DIRECTOR_MAP[id] && DIRECTOR_MAP[id][DISPLAY_NAME]
    end 

    private

    # Map director ids->names and ids->initials
    # Only filled in since 2007 or so, once the preapp data in meetings is parseable
    INITIALS = 0
    FIRST_NAME = 1
    DISPLAY_NAME = 2
    DIRECTOR_MAP = {
      'bayard' => ['hy', 'Henri', 'Henri Yandell'],
      'bdelacretaz' => ['bd', 'Bertrand', 'Bertrand Delacretaz'],
      'brett' => ['bp', 'Brett', 'Brett Porter'],
      'brianm' => ['bmc', 'Brian', 'Brian McCallister'],
      'cliffs' => ['cs', 'Cliff', 'Cliff Schmidt'],
      'coar' => ['kc', 'Ken', 'Ken Coar'],
      'curcuru' => ['sc', 'Shane', 'Shane Curcuru'],
      'cutting' => ['dc', 'Doug', 'Doug Cutting'],
      'dirkx' => ['dg', 'Dirk-Willem', 'Dirk-Willem van Gulik'],
      'dkulp' => ['dk', 'Daniel', 'Daniel Kulp'],
      'druggeri' => ['dr', 'Daniel', 'Daniel Ruggeri'],
      'fielding' => ['rf', 'Roy', 'Roy T. Fielding'],
      'geirm' => ['gmj', 'Geir', 'Geir Magnusson Jr'],
      'gstein' => ['gs', 'Greg', 'Greg Stein'],
      'isabel' => ['idf', 'Isabel', 'Isabel Drost-Fromm'],
      'jerenkrantz' => ['je', 'Justin', 'Justin Erenkrantz'],
      'jim' => ['jj', 'Jim', 'Jim Jagielski'],
      'jmclean' => ['jm', 'Justin', 'Justin Mclean'],
      'ke4qqq' => ['dn', 'David', 'David Nalley'],
      'lrosen' => ['lr', 'Larry', 'Lawrence Rosen'],
      'markt' => ['mt', 'Mark', 'Mark Thomas'],
      'marvin' => ['mh', 'Marvin', 'Marvin Humphrey'],
      'mattmann' => ['cm', 'Chris', 'Chris Mattmann'],
      'myrle' => ['mk', 'Myrle', 'Myrle Krantz'],
      'niclas' => ['nh', 'Niclas', 'Niclas Hedhman'],
      'noirin' => ['np', 'Noirin', 'Noirin Plunkett'],
      'pats' => ['ps', 'Patricia', 'Patricia Shanahan'],
      'psteitz' => ['ps', 'Phil', 'Phil Steitz'],
      'rbowen' => ['rb', 'Rich', 'Rich Bowen'],
      'rgardler' => ['rg', 'Ross', 'Ross Gardler'],
      'rubys' => ['sr', 'Sam', 'Sam Ruby'],
      'rvs' => ['rs', 'Roman', 'Roman Shaposhnik'],
      'striker' => ['ss', 'Sander', 'Sander Striker'],
      'tdunning' => ['td', 'Ted', 'Ted Dunning'],
      'wave' => ['df', 'Dave', 'Dave Fisher'],
      'wohali' => ['jt', 'Joan', 'Joan Touzet'],
    }

  end
end
