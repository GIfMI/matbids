function new_path = build_path(entities, path_patterns, varargin)
    %     """
    %     Constructs a path given a set of entities and a list of potential
    %     filename patterns to use.
    %
    %     Args:
    %         entities (dict): A dictionary mapping entity names to entity values.
    %         path_patterns (str, list): One or more filename patterns to write
    %             the file to. Entities should be represented by the name
    %             surrounded by curly braces. Optional portions of the patterns
    %             should be denoted by square brackets. Entities that require a
    %             specific value for the pattern to match can pass them inside
    %             carets. Default values can be assigned by specifying a string after
    %             the pipe operator. E.g., (e.g., {type<image>|bold} would only match
    %             the pattern if the entity 'type' was passed and its value is
    %             "image", otherwise the default value "bold" will be used).
    %                 Example 1: 'sub-{subject}/[var-{name}/]{id}.csv'
    %                 Result 2: 'sub-01/var-SES/1045.csv'
    %         strict (bool): If True, all passed entities must be matched inside a
    %             pattern in order to be a valid match. If False, extra entities will
    %             be ignored so long as all mandatory entities are found.
    %
    %     Returns:
    %         A constructed path for this file based on the provided patterns.
    %     """
    
    % clear all
    % clc
    % entities.subject = 1;
    % entities.session = 2;
    % entities.acquisition = 3;
    % entities.contrast = 4;
    % entities.reconstruction = 5;
    % entities.suffix = 'T1w';
    %
    %
    % path_patterns = {   'sub-{subject}[/ses-{session}]/anat/sub-{subject}[_ses-{session}][_acq-{acquisition}][_ce-{contrast}][_rec-{reconstruction}]_{suffix<T1w|T2w|T1rho|T1map|T2map|T2star|FLAIR|FLASH|PDmap|PD|PDT2|inplaneT[12]|angio>}.nii.gz',
    %                     'sub-{subject}[/ses-{session}]/anat/sub-{subject}[_ses-{session}][_acq-{acquisition}][_ce-{contrast}][_rec-{reconstruction}][_mod-{modality}]_{suffix<defacemask>}.nii.gz'};
    % strict = true;
    p = inputParser;
    addRequired(p, 'entities', @(x)validateattributes(x,{'struct'},{}));
    addRequired(p, 'path_patterns', @(x)validateattributes(x,{'cell'},{}));
    addOptional(p, 'strict', false, @(x)validateattributes(x,{'logical', 'double'},{'nonempty'}));
    parse(p, entities, path_patterns, varargin{:});
    
    strict = logical(p.Results.strict);
    
    new_path = '';
    
    % More work to do: check if value of a an entity matches the allowed
    % values of the entity in a certain pattern
    
    % Loop over available patterns, return first one that matches all
    for i = 1:numel(path_patterns)
        pattern = path_patterns{i};
        
        % If strict, all entities must be contained in the pattern
        if strict
            
            % improved regular expression
            defined = regexp(pattern, '\{(.*?)(?:<[^>]+>(?:\|.*)?)?\}', 'tokens');
            %defined = regexp(pattern, '\{(.*?)(?:<[^>]+>)?\}', 'tokens');
            
            %             for d_=defined
            %                d = d_{1};
            %                if ~isempty(d{2})
            %                    %for o_ =
            %                    d{2}
            %                    % o = o_{1}
            %                     opts = regexp(d{2}, '<(.*)[|]>', 'tokens')
            %
            %                    %end
            %                end
            %             end
            %             continue
            
            defined = sort(unique(cellfun(@(x) x{1}, defined, 'uni', false)));
            fnames = sort(fieldnames(entities));
            if ~isempty(setdiff({defined{:}}, {fnames{:}}))
            %if ~isempty(setdiff({fnames{:}}, {defined{:}}))
                continue
            end
        end
        
        % Iterate through the provided path patterns
        new_path = pattern;
        optional_patterns = regexp(pattern, '\[(.*?)\]', 'tokens');
        % First build from optional patterns if possible
        for j = 1:numel(optional_patterns)
            optional_pattern = optional_patterns{j}{1};
            optional_chunk = replace_entities(entities, optional_pattern);
            if isempty(optional_chunk)
                optional_chunk = '';
            end;
            new_path = strrep(new_path, sprintf('[%s]', optional_pattern), optional_chunk);
        end
        %Replace remaining entities
        new_path = replace_entities(entities, new_path);
        
        if ~isempty(new_path)
            break
        end
    end
end