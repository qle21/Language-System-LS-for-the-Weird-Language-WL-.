# Base class for Weird Language instructions.
class WL
  def current_execute(program_memory, data_memory, pc)
    raise NotImplementedError, "Execute method has not yet been implemented"
  end
end

# VARINT instruction in Weird Language.
# Assigns an integer i to a variable x.
# Variable x is implicitly declared the first time it is used.
class VARINT < WL
  def initialize(var, i)
    @var = var
    @value = i
  end

  def current_execute(program_memory, data_memory, pc)
    data_memory[@var] = @value
    pc += 1
    [program_memory, data_memory, pc]
  end
end

# VARLIST instruction in Weird Language.
# Assigns a list to a variable y.
# Variable y is implicitly declared the first time it is used.
# The list will contain a variable number of arguments provided in a comma-separated sequence.
# Each argument arg1, arg2, etc. can be either an integer constant or a variable denoting a list or an integer.
class VARLIST < WL
  def initialize(var, *args)
    @var = var
    @args = args
  end

  def current_execute(program_memory, data_memory, pc)
    @args = @args.map { |arg| data_memory[arg] || arg.to_i }
    data_memory[@var] = @args
    pc += 1
    [program_memory, data_memory, pc]
  end
end

# COMBINE instruction in Weird Language.
# Concatenates list1 with list2, and stores the resulting list back into list2.
class COMBINE < WL
  def initialize(list1, list2)
    @list1 = list1
    @list2 = list2
  end

  def current_execute(program_memory, data_memory, pc)
    if data_memory.key?(@list1) && data_memory.key?(@list2)
      combined_list = data_memory[@list1] + data_memory[@list2]
      data_memory[@list2] = combined_list
    end
    pc += 1
    [program_memory, data_memory, pc]
  end
end

# GET instruction in Weird Language.
# Assigns the i-th element of list to variable x.
# Variable x is implicitly declared the first time it is used.
# Assumes that index i is within bounds.
class GET < WL
  def initialize(var, i, list)
    @var = var
    @index = i
    @list = list
  end

  def current_execute(program_memory, data_memory, pc)
    data_memory[@var] = data_memory[@list][@index]
    pc += 1
    [program_memory, data_memory, pc]
  end
end

# SET instruction in Weird Language.
# Sets the i-th element of list to x.
# Variable x could be an integer constant or a variable denoting either a list or an integer.
# Assumes that index i is within bounds.
class SET < WL
  def initialize(var, i, list)
    @var = var
    @index = i
    @list = list
  end

  def current_execute(program_memory, data_memory, pc)
    value = data_memory[@var] || @var
    # Ensure the assigned value is an integer
    data_memory[@list][@index] = value.is_a?(String) ? value.to_i : value
    pc += 1
    [program_memory, data_memory, pc]
  end
end

# COPY instruction in Weird Language.
# Deep copies the content of list2 into list1.
class COPY < WL
  def initialize(list1, list2)
    @list1 = list1
    @list2 = list2
  end

  def current_execute(program_memory, data_memory, pc)
    data_memory[@list1] = backup_copy(data_memory[@list2])
    pc += 1
    [program_memory, data_memory, pc]
  end

  # You need to back up a copy otherwise when you set the value it will apply to all the list
  private

  def backup_copy(obj)
    if obj.is_a?(Array)
      obj.map { |item| backup_copy(item) }
    else
      obj
    end
  end
end

# CHS instruction in Weird Language.
# Changes the sign of the integer value bound to x.
# Assumes that x is either an int constant or int variable.
class CHS < WL
  def initialize(var)
    @var = var
  end

  def current_execute(program_memory, data_memory, pc)
    data_memory[@var] = -data_memory[@var]
    pc += 1
    [program_memory, data_memory, pc]
  end
end

# ADD instruction in Weird Language.
# Adds the integers bound to the two arguments and stores the result in x.
class ADD < WL
  def initialize(var, jy)
    @var = var
    @jy = jy
  end

  def current_execute(program_memory, data_memory, pc)
    data_memory[@var] += data_memory[@jy].to_i || @jy.to_i
    pc += 1
    [program_memory, data_memory, pc]
  end
end

# IF instruction in Weird Language.
# If x is an empty list or the number zero, jumps to the instruction at line i.
class IF < WL
  def initialize(var, i)
    @var = var
    @i = i
  end

  def current_execute(program_memory, data_memory, pc)
    if data_memory[@var] == 0 || data_memory[@var].empty?
      pc = @i
    else
      pc += 1
    end
    [program_memory, data_memory, pc]
  end
end

# Represents the HLT instruction in Weird Language.
# Terminates program execution.
class HLT < WL
  def current_execute(program_memory, data_memory, pc)
    puts "Terminates program execution."
    exit
  end
end

# Language System (LS) for the Weird Language (WL).
class LS
  def initialize
    @program_memory = []
    @data_memory = {}
    @pc = 0
  end

  # Reads a WL program from the input file.
  def read_program(file)
    @program_memory = File.readlines(file).map(&:chomp)
  end

  # Executes a single line of code, starting from line 0.
  # Updates the PC and the data memory according to the instruction.
  # Prints the resulting values of the data memory and the PC.
  def execute_single_line
    instruction = particular_instruction(@program_memory[@pc])
    program_memory, data_memory, pc = instruction.current_execute(@program_memory, @data_memory, @pc)
    @program_memory = program_memory
    @data_memory = data_memory
    @pc = pc
    print_state
  end

  # Executes all instructions until a halt instruction is encountered or there are no more instructions to be executed.
  # Prints the values of the PC and the data memory.
  def execute_all
    while @pc < @program_memory.length
      execute_single_line
    end
  end

  # Provides a command loop consisting of three commands:
  # 'o' - Execute a single line of code.
  # 'a' - Executes all instructions until a halt instruction is encountered or there are no more instructions to be executed.
  # 'q' - Quits the command loop.
  def command_loop
    loop do
      puts "Enter command (o/a/q):"
      command = gets.chomp.downcase

      case command
      when 'o'
        execute_single_line
      when 'a'
        execute_all
      when 'q'
        break
      else
        puts "Invalid command. Please enter 'o', 'a', or 'q'."
      end
    end
  end

  private

  # Prints the current state, including the execute line, and the current data in memory.
  def print_state
    puts "Execute line: #{@pc - 1}"
    puts "Current memory:"
    @data_memory.each do |var, value|
      puts "#{var} = #{value}"
    end
    puts "+++++++++++++++++++++++++++++++++++++++++"
  end

  # Creates an instance of a particular instruction based on the command in the input line.
  def particular_instruction(line)
    command, *args = line.split
    case command
    when "VARINT"
      VARINT.new(args[0], args[1].to_i)
    when "VARLIST"
      VARLIST.new(args[0], *args[1..-1])
    when "COMBINE"
      COMBINE.new(args[0], args[1])
    when "GET"
      GET.new(args[0], args[1].to_i, args[2])
    when "SET"
      SET.new(args[0], args[1].to_i, args[2])
    when "COPY"
      COPY.new(args[0], args[1])
    when "CHS"
      CHS.new(args[0])
    when "ADD"
      ADD.new(args[0], args[1])
    when "IF"
      IF.new(args[0], args[1].to_i)
    when "HLT"
      HLT.new
    else
      raise ArgumentError, "Invalid instruction: #{command}"
    end
  end
end

# How to use
ls = LS.new
ls.read_program("input.wl")
ls.command_loop
