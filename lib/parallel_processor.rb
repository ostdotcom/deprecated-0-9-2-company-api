class ParallelProcessor

  include Util::ResultHelper

  # Initialize
  #
  # * Author: Puneet
  # * Date: 02/02/2018
  # * Reviewed By:
  #
  # @param [Hash] methods_to_process (mandatory) - indexed by some key value should be Procs
  #
  def initialize(no_of_concurrrent_txs, methods_to_process)

    @no_of_concurrrent_txs = no_of_concurrrent_txs
    @methods_to_process = methods_to_process

    @response = {}

  end

  # Perform
  #
  # * Author: Puneet
  # * Date: 01/02/2018
  # * Reviewed By:
  #
  # @return [Result::Base]
  #
  def perform

    batch_no = 1
    failed_count = 0

    @methods_to_process.keys.each_slice(max_allowed_threads) do |batched_keys|

      puts "starting batch_no: #{batch_no} having #{batched_keys.length} transactions"

      threads = []

      @time = Benchmark.realtime do
        batched_keys.each do |key|
          thread = Thread.new {
            @response[key] = @methods_to_process[key].call
            unless @response[key].success?
              puts @response[key].inspect
              failed_count += 1
            end
          }
          threads.push(thread)
        end
      end

      threads.each { |thread| thread.join } # make others wait for the one taking time

      puts "batch_no: #{batch_no} took #{@time.to_s}"
      batch_no += 1

    end
    puts "failed_count---#{failed_count}"

    success_with_data(@response)

  end

  private

  def max_allowed_threads
    @no_of_concurrrent_txs
  end

end