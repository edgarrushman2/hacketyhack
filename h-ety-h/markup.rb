require 'h-ety-h/syntax'

module HH::Markup

  TOKENIZER = HH::Syntax.load "ruby"
  COLORS = {
    :comment => {:stroke => "#887"},
    :keyword => {:stroke => "#111"},
    :method => {:stroke => "#C09", :weight => "bold"},
    # :class => {:stroke => "#0c4", :weight => "bold"},
    # :module => {:stroke => "#050"},
    # :punct => {:stroke => "#668", :weight => "bold"},
    :symbol => {:stroke => "#C30"},
    :string => {:stroke => "#C90"},
    :number => {:stroke => "#396" },
    :regex => {:stroke => "#000", :fill => "#FFC" },
    # :char => {:stroke => "#f07"},
    :attribute => {:stroke => "#369" },
    # :global => {:stroke => "#7FB" },
    :expr => {:stroke => "#722" },
    # :escape => {:stroke => "#277" }
    :ident => {:stroke => "#A79"},
    :constant => {:stroke => "#630", :weight => "bold"},
    :class => {:stroke => "#630", :weight => "bold"},
    :matching => {:stroke => "#ff0", :weight => "bold"},
  }

  
  def highlight str, pos=nil, colors=COLORS
    tokens = []
    TOKENIZER.tokenize(str) do |t|
      if t.group == :punct
        # split punctuation into single characters tokens
        # TODO: to it in the parser
        tokens += t.split('').map{|s| HH::Syntax::Token.new(s, :punct)}
      else
        # add token as is
        tokens << t
      end
    end

    res = []
    tokens.each do |token|
      #puts "'#{token}' #{token.group}/#{token.instruction}"
      res <<
        if colors[token.group]
          span(token, colors[token.group])
        elsif colors[:any]
          span(token, colors[:any])
        else
          token
        end
      # puts "#{token} {group: #{token.group}, instruction: #{token.instruction}}"
    end

    if not pos
      return res
    end

    token_index, matching_index = matching_token(tokens, pos)

    if token_index
      res[token_index] = span(tokens[token_index], colors[:matching])
      if matching_index
        res[matching_index] = span(tokens[matching_index], colors[:matching])
      end
    end

    res
  end


  def matching_token(tokens, pos)
    curr_pos = 0
    token_index = nil
    tokens.each_with_index do |t, i|
      curr_pos += t.size
      if token_index.nil? and curr_pos >= pos
        token_index = i
        break
      end
    end
    #debugger
    if token_index.nil? then return nil end

    match = matching_token_at_index(tokens, token_index);
    if match.nil? and curr_pos == pos and token_index < tokens.size-1
      # try the token before the cursor, instead of the one after
      #debugger
      match = matching_token(tokens, token_index+1)
    end

    match
  end


  # tries only one index
  # may be called twice by matching_token() using the index before and after
  # the cursor
  #
  # returns nil if the token isn't a start or end of anything
#  def matching_token_at_index(tokens, token_index)
#    token = tokens[token_index]
#    if BRACKETS.include?(token)
#      return[token_index, matching_bracket(tokens, token_index)]
#    elsif (OPEN_BLOCK + ['end']).include?(token)
#      return [token_index, matching_block(tokens, token_index)]
#    else
#      # token uninteresting
#      return nil
#    end
#  end
#
#
#  def matching_bracket(tokens, index)
#    token = tokens[index]
#    if (matching = OPEN_BRACKETS[token])
#      direction = 1
#    elsif (matching = CLOSE_BRACKETS[token])
#      direction = -1
#    else
#      # something strange happened..
#      raise "internal error: unknown bracket"
#    end
#
#    return matching_token(tokens, index, [matching], direction)
#  end
#
#
#  def matching_block(tokens, index)
#    token = tokens[index]
#    if (token == 'end')
#      direction = -1
#      matching_tokens = OPEN_BLOCK;
#    else
#      direction = 1
#      matching_tokens = ['end']
#    end
#
#    return matching_token(tokens, index, [matching_tokens], direction)
#  end


  def matching_token(tokens, index)
    token = tokens[index]
    starts, ends, direction = matching_tokens(token)

    stack_level = 1
    while index >= 0 and index < tokens.size
      index += direction
      t = tokens[index]
      if ends.include?(t)
        stack_level -= 1
        return index if stack_level == 0
      elsif starts.include?(t)
        stack_level += 1
      end
    end
    # no matching token found
    return nil
  end

  # returns an array of tokens matching and the direction
  def matching_tokens(token)
    starts = [token]
    if OPEN_BRACKETS[token]
      direction = 1
      ends = [OPEN_BRACKETS[token]]
    elsif CLOSE_BRACKETS[token]
      direction = -1
      ends = [CLOSE_BRACKETS[token]]
    elsif OPEN_BLOCK.include?(token)
      direction = 1
      ends = ['end']
      starts = OPEN_BLOCK
    elsif token == 'end'
      direction = -1
      ends = OPEN_BLOCK
    else
      return nil
    end

    [starts, ends, direction]
  end


  OPEN_BRACKETS = {
    '{' => '}',
    '(' => ')',
    '[' => ']',
  }

  #close_bracket = {}
  #OPEN_BRACKETS.each{|open, close| opens_bracket[close] = open}
  #CLOSE_BRACKETS = opens_bracket
  # the following is more readable :)
  CLOSE_BRACKETS = {
    '}' => '{',
    ')' => '(',
    ']' => '[',
  }

  BRACKETS = CLOSE_BRACKETS.keys + OPEN_BRACKETS.keys

  OPEN_BLOCK = [
    'def',
    'class',
    'module',
    'do',
    'if',
    'unless',
    'while',
    'begin'
  ]
#  MATCH_CLOSES = {
#    ['do', :keyword] => ['end'],
#    ['class', :keyword] => ['end'],
#    ['module', :keyword] => ['end'],
#    ['def', :keyword] => ['end'],
#    ['if', :keyword] => ['end'],
#    ['{', :punct] => ['}'],
#    ['[', :punct] => [']'],
#    ['(', :punct] => [')']
#  }

end
