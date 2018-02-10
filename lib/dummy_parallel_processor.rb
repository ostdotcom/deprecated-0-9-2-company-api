class DummyParallelProcessor

  def dummy_method(i)
    puts "sleeping stary form #{i}"
    sleep(5)
    puts "sleeping end form #{i}"
    return i
  end

  proc1 = Proc.new do
    dummy_method(1)
  end

  proc2 = Proc.new do
    dummy_method(2)
  end

  proc3 = Proc.new do
    dummy_method(3)
  end

  proc4 = Proc.new do
    dummy_method(4)
  end

  proc5 = Proc.new do
    dummy_method(5)
  end

  proc6 = Proc.new do
    dummy_method(6)
  end

  data = {
      proc1: proc1,
      proc2: proc2,
      proc3: proc3,
      proc4: proc4,
      proc5: proc5,
      proc6: proc6
  }

  ParallelProcessor.new(data).perform

end

