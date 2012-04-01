require 'detroit/tool'

module Detroit

  # Create new RI tool with specified +options+.
  def RI(options={})
    RI.new(options)
  end

  # The ri documentation tool provides services for
  # generating ri documentation.
  #
  # By default it generates the ri documentaiton at `.rdoc`,
  # unless an 'ri' directory exists in the project's root
  # directory, in which case the ri documentation will be
  # stored there.
  #
  class RI < Tool

    # Default location to store ri documentation files.
    DEFAULT_OUTPUT       = ".rdoc"

    # Locations to check for existence in deciding where to store ri documentation.
    DEFAULT_OUTPUT_MATCH = "{.rdoc,.ri,ri,doc/ri}"

    # Default extra options to add to rdoc call.
    DEFAULT_EXTRA        = ''

    #
    def initialize_defaults
      @files  = metadata.loadpath
      @output = Dir[DEFAULT_OUTPUT_MATCH].first || DEFAULT_OUTPUT
      @extra  = DEFAULT_EXTRA
    end

    # Where to save rdoc files (doc/rdoc).
    attr_accessor :output

    # Which files to include.
    attr_accessor :files

    # Alternate term for #files.
    alias_accessor :include, :files

    # Paths to specifically exclude.
    attr_accessor :exclude

    # Additional options passed to the rdoc command.
    attr_accessor :extra


    #  A S S E M B L Y  M E T H O D S

    #
    def assemble?(station, options={})
      when station
      case :document then true
      case :reset    then true
      case :clean    then true
      case :purge    then true
      end
    end

    # Attach to document, reset and purge assembly stations.
    def assemble(station, options={})
      when station
      case :document then document
      case :reset    then reset
      case :clean    then clean
      case :purge    then purge
      end
    end

    # Generate ri documentation. This utilizes
    # rdoc to produce the appropriate files.
    #
    def document
      output  = self.output
      input   = self.files
      exclude = self.exclude

      include_files = files.to_list.uniq
      exclude_files = exclude.to_list.uniq

      filelist = amass(include_files, exclude_files)

      if outofdate?(output, *filelist) or force?
        status "Generating #{output}"

        argv = ['--ri']
        argv.concat(extra.split(/\s+/))
        argv.concat ['--output', output]
        #argv.concat ['--exclude', exclude] unless exclude.empty?

        argv = argv + filelist

        dir = ri_target(output, argv)

        touch(output)

        output
      else
        status "RI docs are current (#{output})"
      end
    end

    # Set the output directory's mtime to furthest time in past.
    # This "marks" the documentation as out-of-date.
    def reset
      if File.directory?(output)
        File.utime(0,0,self.output)
        report "reset #{output}"
      end
    end

    # A no-op, there are no residuals to remove.
    def clean
    end

    # Remove ri products.
    def purge
      if File.directory?(output)
        rm_r(output)
        report "Removed #{output}" #unless trial?
      end
    end

  private

    # Generate ri docs for input targets.
    #
    # TODO: Use RDoc programmatically rather than via shell.
    #
    def ri_target(output, argv=[])
      rm_r(output) if exist?(output) and safe?(output)  # remove old ri docs

      if trial?
        puts "rdoc " + argv.join(" ")
      else
        trace "rdoc " + argv.join(" ") #if trace? or verbose?
        #silently do
        rdoc = ::RDoc::RDoc.new
        rdoc.document(argv)
        #end
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
      File.dirname(__FILE__)+'/../man/detroit-ri.5'
    end

  end

end