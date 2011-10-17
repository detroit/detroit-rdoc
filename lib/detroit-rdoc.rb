require 'detroit/tool'

module Detroit

  # Create a new RDoc tool with the specified +options+.
  def RDoc(options={})
    RDoc.new(options)
  end

  # RDoc documentation tool generates RDocs for Ruby project.
  #
  # By default it generates the rdoc documentaiton at doc/rdoc,
  # unless an 'rdoc' directory exists in the project's root
  # directory, in which case the rdoc documentation will be
  # stored there.
  #
  class RDoc < Tool

    # Default location to store rdoc documentation files.
    DEFAULT_OUTPUT       = "doc"

    # Locations to check for existance in deciding where to store rdoc documentation.
    DEFAULT_OUTPUT_MATCH = "{site/rdoc,doc/rdoc,rdoc}"

    # Default main file.
    DEFAULT_MAIN         = "README{,.*}"

    # Default rdoc format to use.
    DEFAULT_FORMAT       = "darkfish"

    # Deafult extra options to add to rdoc call.
    DEFAULT_EXTRA        = ''


    #  A T T R I B U T E S

    # Title of documents. Defaults to general metadata title field.
    attr_accessor :title

    # Where to save rdoc files (doc/rdoc).
    attr_accessor :output

    # Format to use (defaults to ENV['RDOC_FORMAT'] or 'darkfish')
    attr_accessor :format

    # Template to use (defaults to ENV['RDOC_TEMPLATE'])
    attr_accessor :template

    # Main file.  This can be a file pattern. (README{,.*})
    attr_accessor :main

    # Which files to document.
    attr_reader :files

    #
    def files=(list)
      @resolved_files = nil
      @files = list.to_list
    end

    # Alias for +files+.
    alias_accessor :include, :files

    # Paths to specifically exclude.
    attr_accessor :exclude

    # File patterns to ignore.
    attr_accessor :ignore

    # Ad file html snippet to add to html rdocs.
    attr_accessor :adfile

    # Additional options passed to the rdoc command.
    attr_accessor :extra


    #  A S S E M B L Y  S T A T I O N S

    # Attach document method to document assembly station.
    def station_document
      document
    end

    # Attach reset method to reset assembly station.
    def station_reset
      rest
    end

    # Attach purge method to purge assembly station.
    def station_purge
      purge
    end


    #  S E R V I C E  M E T H O D S

    # Generate Rdoc documentation. Settings are the
    # same as the rdoc command's option, with two
    # exceptions: +inline+ for +inline-source+ and
    # +output+ for +op+.
    #
    def document
      title    = self.title
      output   = self.output
      main     = self.main
      format   = self.format
      template = self.template
      adfile   = self.adfile
      extra    = self.extra

      # you can specify more than one possibility, first match wins
      adfile = [adfile].flatten.compact.find do |f|
        File.exist?(f)
      end

      main = Dir.glob(main, File::FNM_CASEFOLD).first

      #include_files  = files.to_list.uniq
      #exclude_files  = exclude.to_list.uniq
      #ignore_matches = ignore.to_list.uniq

      #if mfile = project.manifest.file
      #  exclude_files << mfile.basename.to_s # TODO: I think base name should retun a string?
      #end

      #filelist = amass(include_files, exclude_files, ignore_matches)
      #filelist = filelist.select{ |fname| File.file?(fname) }

      if (msg = current?) && !force?
        report msg
      else
        status "Generating #{output}"

        pdir = File.dirname(output)
        mkdir_p(pdir) unless directory?(pdir)

        #target_main = Dir.glob(target['main'].to_s, File::FNM_CASEFOLD).first
        #target_main   = File.expand_path(target_main) if target_main
        #target_output = File.expand_path(File.join(output, subdir))
        #target_output = File.join(output, subdir)

        argv = []
        argv.concat(extra.split(/\s+/))
        argv.concat ['--op', output]
        argv.concat ['--main', main] if main
        argv.concat ['--format', format] if format
        argv.concat ['--template', template] if template
        argv.concat ['--title', title] if title

        #exclude_files = self.exclude.to_list.uniq
        #exclude_files.each do |file|
        #  argv.concat ['--exclude', file]
        #end

        argv = argv + resolved_files

        rdoc_target(output, argv)
        rdoc_insert_ads(output, adfile)

        touch(output)

        output
      end
    end

    # Are RDocs current and not in need of updating?
    # If yes, returns string message, otherwise `false`.
    def current?
      if outofdate?(output, *resolved_files)
        return false
      else
        "RDocs are current (#{output})"
      end
    end

    # Reset output directory, marking it as out-of-date.
    def reset
      if directory?(output)
        utime(0, 0, output)
        report "Reset #{output}"
      end
    end

    # A no-op. RDoc has no residuals to remove.
    def clean
    end

    # Remove rdoc output.
    def purge
      if directory?(output)
        rm_r(output)
        report "Removed #{output}"
      end
    end

  private

    #
    #def initialize_requires
    #  # NOTE: Due to a bug in RDoc this needs to be done for now
    #  # so that alternate templates can be used.
    #  begin
    #    require 'rubygems'
    #    gem('rdoc')
    #  rescue LoadError
    #    $stderr.puts "Oh no! No modern rdoc!"
    #  end
    #  require 'rdoc/rdoc'
    #end

    # Setup default attribute values.
    def initialize_defaults
      @title    = metadata.title
      @files    = metadata.loadpath + ['[A-Z]*', 'bin'] # DEFAULT_FILES
      @output   = Dir[DEFAULT_OUTPUT_MATCH].first || DEFAULT_OUTPUT
      @extra    = DEFAULT_EXTRA
      @main     = Dir[DEFAULT_MAIN].first || 'README'
      @format   = ENV['RDOC_FORMAT'] || DEFAULT_FORMAT
      @template = ENV['RDOC_TEMPLATE']
    end

    #
    def resolved_files
      @resolved_files ||= (
        include_files  = self.files.to_list.uniq
        exclude_files  = self.exclude.to_list.uniq
        ignore_matches = self.ignore.to_list.uniq

        if mfile = project.manifest.file
          exclude_files << mfile.basename.to_s # TODO: I think base name should retun a string?
        end

        list = amass(include_files, exclude_files, ignore_matches)
        list = list.select{ |fname| File.file?(fname) }
        list
      )
    end

    # Generate rdocs for input targets.
    def rdoc_target(output, argv=[])
      rm_r(output) if exist?(output) and safe?(output)  # remove old rdocs

      #rdocopt['op'] = output

      #if template == 'hanna'
      #  cmd = "hanna #{extra} " + [input, rdocopt].to_console
      #else
      #  cmd = "rdoc #{extra} " + [input, rdocopt].to_console
      #end

      #argv = ("#{extra}" + [input, rdocopt].to_console).split(/\s+/)

      if trial?
        puts "rdoc " + argv.join(" ")
      else
        trace "rdoc " + argv.join(" ") #if trace? or verbose?
        rdoc = ::RDoc::RDoc.new
        rdoc.document(argv)
        #silently do
        #  sh(cmd) #shell(cmd)
        #end
      end
    end

    # Insert an ad into rdocs, if exists.
    #
    # Note that this code is needs work, as is it
    # was designed to work with an old version of RDoc.
    #
    def rdoc_insert_ads(site, adfile)
      return if trial?
      return unless adfile && File.file?(adfile)
      adtext = File.read(adfile)
      #puts
      dirs = Dir.glob(File.join(site,'*/'))
      dirs.each do |dir|
        files = Dir.glob(File.join(dir, '**/*.html'))
        files.each do |file|
          html = File.read(file)
          bodi = html.index('<body>')
          next unless bodi
          html[bodi + 7] = "\n" + adtext
          File.write(file, html) unless trial?
        end
      end
    end

    #
    def require_rdoc
      # NOTE: Due to a bug in RDoc this needs to be done for now
      # so that alternate templates can be used.
      begin
        require 'rubygems'
        gem('rdoc')
      rescue LoadError
        $stderr.puts "Oh no! No modern rdoc!"
      end
      #require 'rdoc'
      require 'rdoc/rdoc'
    end

    #
    def initialize_requires
      require_rdoc
    end

  public

    def self.man_page
      File.dirname(__FILE__)+'/../man/detroit-minitest.5'      
    end

  end

end
