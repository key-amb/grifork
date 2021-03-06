class Grifork::CLI
  def run(argv)
    OptionParser.new do |opt|
      opt.on('-f', '--file Griforkfile') { |f| @taskfile      = f }
      opt.on('-o', '--override-by FILE') { |f| @override_file = f }
      opt.on('-r', '--on-remote')        { @on_remote = true }
      opt.on('-n', '--dry-run')          { @dry_run   = true }
      opt.on('-v', '--version')          { @version   = true }
      opt.parse!(argv)
    end
    if @version
      puts Grifork::VERSION
      exit
    end

    config = load_taskfiles
    if @dry_run
      config.dry_run = true
    end
    config.freeze
    Grifork.configure!(config)
    logger = Grifork.logger

    graph = Grifork::Graph.new(config.hosts)

    logger.info("START | mode: #{config.mode}")
    if @on_remote
      puts "Start on remote. Hosts: #{config.hosts}"
    end

    case config.mode
    when :standalone
      graph.launch_tasks
    when :grifork
      graph.grifork
    else
      # Never comes here
      raise "Unexpected mode! #{config.mode}"
    end

    logger.info("END | mode: #{config.mode}")
    if @on_remote
      puts "End on remote."
    end
  end

  private

  def load_taskfiles
    puts "Load settings from #{taskfile}"
    dsl = Grifork::DSL.load_file(taskfile, on_remote: @on_remote)
    if @override_file
      dsl.load_and_merge_config_by!(@override_file)
    end
    config = dsl.to_config
    config.griforkfile = taskfile
    config
  end

  def taskfile
    @taskfile || ENV['GRIFORKFILE'] || Grifork::DEFAULT_TASKFILE
  end
end
