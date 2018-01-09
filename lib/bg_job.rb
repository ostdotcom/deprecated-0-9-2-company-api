class BgJob

  extend Sanitizer

  def self.enqueue(klass, enqueue_params, options = {})
    # Set default values to options
    options.reverse_merge!(emails: '',
                           subject: "[#{Rails.env}]: Exception occurred while trying to enqueue job to resque",
                           safe: true,
                           fallback_run_sync: true,
                           force_run_sync: Rails.env.development?)
    q_name = options[:queue] || klass.queue_name

    # if force_run_sync or if it is dev env, run the job synchronously
    if options[:force_run_sync]
      return perform_job_synchronously(klass, enqueue_params, q_name)
    else
      enqueue_params = hashify_params_recursively(enqueue_params)
      if options[:wait].present?
        klass.set(queue: q_name, wait: options[:wait]).perform_later(enqueue_params)
      else
        klass.set(queue: q_name).perform_later(enqueue_params)
      end
    end

  rescue => e
    Rails.logger.error("Resque enqueue failed with params #{enqueue_params}. Exception: #{e.message}")

    perform_job_synchronously(klass, enqueue_params, q_name) if options[:fallback_run_sync]

      Rails.logger.error { e }

      ApplicationMailer.notify(
        body: {exception: {message: e.message, backtrace: e.backtrace}},
        data: {
          'enqueue_params' => enqueue_params,
          'class_name' => klass,
          'options' => options,
        },
        subject: 'Exception in Resque enqueue'
      ).deliver

      # send mail when redis down
      #w hy raise?? when fallback run sync
      # raise if !options[:safe] || !options[:fallback_run_sync]

  end

  def self.perform_job_synchronously(klass, enqueue_params, q_name)
    job = klass.new
    Rails.logger.info("Performing Job (#{job.class}) synchronously")
    job.queue_name = q_name
    job.perform(enqueue_params || {})
  rescue => e
    Rails.logger.error("Resque perform_job_synchronously failed with params #{enqueue_params}. Exception: #{e.message}")

    ApplicationMailer.notify(
      body: {exception: {message: e.message, backtrace: e.backtrace}},
      data: {
        'enqueue_params' => enqueue_params,
        'class_name' => klass,
        'q_name' => q_name,
      },
      subject: 'Exception in perform_job_synchronously'
    ).deliver
  end

end