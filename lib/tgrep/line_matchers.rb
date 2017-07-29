
module Tgrep
  TagNameCaseSensitiveCompare = Struct.new(:search) do
    def match?(line)
      line.start_with?(search)
    end
  end

  TagNameCaseInSensitiveCompare = Struct.new(:search) do
    def match?(line)
      line.downcase.start_with?(search)
    end
  end
end
