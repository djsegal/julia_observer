class DownloadJob < JuliaJob
  queue_as :default

  def perform(*args)
    Batch.current_marker_date = Time.zone.now
    set_batch_marker :current_date, Batch.current_marker_date

    FileUtils.rm_rf "tmp/news"
    system "#{@sys_run} news:get_all"

    FileUtils.rm_rf "tmp/github"
    system "#{@sys_run} github:download"
  end

end
