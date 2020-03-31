function new_path = replace_entities(entities, pattern)
    %     Replaces all entity names in a given pattern with the corresponding
    %     values provided by entities.
    %
    %     Args:
    %         entities (dict): A dictionary mapping entity names to entity values.
    %         pattern (str): A path pattern that contains entity names denoted
    %             by curly braces. Optional portions denoted by square braces.
    %             For example: 'sub-{subject}/[var-{name}/]{id}.csv'
    %             Accepted entity values, using regex matching, denoted within angle
    %             brackets.
    %             For example: 'sub-{subject<01|02>}/{task}.csv'
    %
    %     Returns:
    %         A new string with the entity values inserted where entity names
    %         were denoted in the provided pattern.
    % clear all
    % pattern= 'sub-{subject}[/ses-{session}]/[{datatype<func|beh>|func}/]sub-{subject}[_ses-{session}]_task-{task}[_acq-{acquisition}][_rec-{reconstruction}][_run-{run}][_echo-{echo}][_recording-{recording}]_{suffix<physio|stim>}.{extension<tsv|json>|tsv}';
    
%     entities.subject = '03';
%     entities.session = '01';
%     entities.task = 'nback';
%     entities.run = '01';
%     entities.suffix = 'physio';
%     entities.datatype = 'func';
%     entities.extension = 'tsv';
    
    ents = regexp(pattern, '\{(.*?)\}', 'tokens');
    %cellfun(@ disp, ents)
    new_path = pattern;
    
    for i=1:numel(ents)
        ent = ents{i}{1};
        tokens = regexp(ent, '([^|<]+)(<.*?>)?(\|.*)?', 'tokens');
        %cellfun(@ disp, tokens)
        
        if isempty(tokens)
            new_path = [];
            break;
        end
        [name, valid, default] = tokens{1}{:};
        
        if ~isempty(default)
            default = default(2:end);
        end
        
        %valid_str = '';
        if ~isempty(valid)
            valid = valid(2:end-1);
            valid=cellify(strsplit(valid, '|'));
            %valid_str = strjoin(valid,'|');
        end
        
        if isfield(entities, name) && ~isempty(valid)
            if isempty(entities.(name))
                ent_val = '';
            else
                ent_val = castto(entities.(name), 'char');
            end
            
            if ~any(find(strcmp(valid, ent_val)))
                % better to bail out if ent_val is not one of the valid
                % values?
                
                if ~isempty(ent_val)
                    new_path = [];
                    break;
                end
                % or better to keep the default value as escape
                
                if isempty(default)
                    new_path = [];
                    break;
                end
                entities.(name) = default;
            end
        end
        
        if isfield(entities, name)
            ent_val = entities.(name);
        else
            ent_val = default;
        end
        
        if isempty(ent_val)
            new_path = [];
            break;
        end
        
        new_path = strrep(new_path, sprintf('{%s}', ent), castto(ent_val, 'char'));
    end
end
