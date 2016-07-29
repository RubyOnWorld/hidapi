require 'libusb'
require 'hidapi/version'

module HidApi

  raise 'LIBUSB version must be at least 1.0' unless LIBUSB.version.major >= 1

  ##
  # Gets the engine used by the API.
  #
  # All engine methods can be passed through the HidApi module.
  def self.engine
    @engine ||= HidApi::Engine.new
  end


  def self.method_missing(m,*a,&b)    # :nodoc:
    if engine.respond_to?(m)
      engine.send(m,*a,&b)
    else
      # no super available for modules.
      raise NoMethodError, "undefined method `#{m}` for HidApi:Module"
    end
  end


  def self.respond_to_missing?(m)     # :nodoc:
    engine.respond_to?(m)
  end


  ##
  # Processes a debug message.
  #
  # You can either provide a debug message directly or via a block.
  # If a block is provided, it will not be executed unless a debugger has been set and the message is left nil.
  def self.debug(msg = nil, &block)
    if @debugger
      msg = block.call if block_given? && msg.nil?
      @debugger.call(msg)
    end
  end


  ##
  # Sets the debugger to use.
  #
  # :yields: the message to debug
  def self.set_debugger(&block)
    @debugger = block_given? ? block : nil
  end


  private

  if ENV['ENABLE_DEBUG'].to_s.to_i != 0
    set_debugger do |msg|
      msg = msg.to_s.strip
      if msg.length > 0
        @debug_file ||= File.open(File.expand_path('../../tmp/debug.log', __FILE__), 'w')
        @debug_file.write "[#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}] #{msg.gsub("\n", "\n" + (' ' * 22))}\n"
        @debug_file.flush
        STDOUT.print "(debug) #{msg.gsub("\n", "\n" + (' ' * 8))}\n"
      end
    end
  end


end

# load all of the library components.
Dir.glob(File.expand_path('../hidapi/*.rb', __FILE__)) { |file| require file }