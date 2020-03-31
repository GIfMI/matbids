function val = castto(val, dtype)
    % maybe with str2num_fast, no really difference
    % cast a value to a datatype
    if ischar(val)
        switch dtype
            case 'single'
                val=single(str2double(val));
            case 'double'
                val=str2double(val);
        end
        if isnan(val) val = 0; end
        
    elseif isnumeric(val) || islogical(val)
        switch dtype
            case 'char'
                val = num2str(val);
            otherwise
                val = cast(val, dtype);
        end
    else
        error('Data type not supported');
    end
end

%     % cast a value to a datatype
%     if isa(val, 'char')
%         switch dtype
%             case 'single'
%                 val=single(str2double(val));
%             case 'double'
%                 val=str2double(val);
%         end
%         if isempty(val), val = 0; end
%         
%     elseif isnumeric(val) || islogical(val)
%         switch dtype
%             case 'char'
%                 val = num2str(val);
%             otherwise
%                 val = cast(val, dtype);
%         end
%     else
%         error('Data type not supported');
%     end
% end

