function str = escape_string(str)
    if ischar(str)
        str = regexprep(str,'([[\\]{}()=''.(),;:%%{%}!@])','\\$1');
    else
        str = '';
    end
   
    
    %  # $ & * + - . ^_` | :"
    % \#\$\&\*\+\-\.\^_`\|\~: