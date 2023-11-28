class Array
  def sample!(times = 1)
    my_length = self.length
    my_sample = []

    (1..times).map do |_i| 
      my_sample << self.delete_at(rand(my_length))
      my_length-=1
    end
    my_sample
  end
end
