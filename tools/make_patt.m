function patt = make_patt(x, regex_search)
    % fastest implementation but not nicest
    % doubled speed compared to slowest implementation (as in pybids)!!!!!
    if ischar(x)
        % increase speed by avoiding unnecessary casts
        patt = x;
    else
        patt = castto(x, 'char');
    end

    if ~regex_search
        patt = regexptranslate('escape', patt);
        
        if isnumeric(x)
            patt = ['^0*', patt, '$'];
        else
            patt = ['^', patt, '$'];
        end
        return
    end
   
    if isnumeric(x)
        patt = ['0*', patt];
    end
end


% function patt = make_patt(x, regex_search)
%     % fastest implementation but not nicest
%     if ischar(x)
%         % increase speed by avoiding unnecessary casts
%         patt = x;
%     else
%         patt = castto(x, 'char');
%     end
% 
%     if ~regex_search
%         patt = regexptranslate('escape', patt);
%         
%         if isnumeric(x)
%             patt = ['^0*', patt, '$'];
%         else
%             patt = ['^', patt, '$'];
%         end
%         return
%     end
%    
%     if isnumeric(x)
%         patt = ['0*', patt];
%     end
% end


% function patt = make_patt(x, regex_search)
%     patt = castto(x, 'char');
% 
%     if ~regex_search
%         %patt = regex_escstr(patt);
%         patt = [regexptranslate('escape', patt);
%         pre_regexp = '^';
%         post_regexp = '$';
%     else
%         pre_regexp = '';
%         post_regexp = '';
%     end
%    
%     if isa(x, 'numeric')
%         leading_zeros = '0*';
%     else
%         leading_zeros = '';
%     end
%     
%     patt = sprintf('%s%s%s%s', pre_regexp, leading_zeros, patt, post_regexp);
% end
% 
% function patt = make_patt(x, regex_search)
%     patt = castto(x, 'char');
% 
% %     if ~isempty(varargin)
% %         regex_search = logical(varargin{1});
% %     end
% 
%     if ~regex_search
%         patt = regex_escstr(patt);
%     end
%    
%     if isa(x, 'numeric')
%         leading_zeros = '0*';
%     else
%         leading_zeros = '';
%     end
%     
%     if ~regex_search
%         pre_regexp = '^';
%         post_regexp = '$';
%     else
%         pre_regexp = '';
%         post_regexp = '';
%     end
%     
%     patt = sprintf('%s%s%s%s', pre_regexp, leading_zeros, patt, post_regexp);
% end

%slowest implementation
% function patt = make_patt(x, varargin)
%     patt = castto(x, 'char');
% 
%     if ~isempty(varargin)
%         regex_search = logical(varargin{1});
%     end
% 
%     if ~regex_search
%         patt = regex_escstr(patt);
%     end
%    
%     if isa(x, 'numeric')
%         patt = strcat('0*', patt);
%     end
%     
%     if ~regex_search
%         patt = strcat('^', patt, '$');
%     end
% end