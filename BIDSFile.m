% TODO
% change validateattributes to layout object
% load image file

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
%
% bfile = BIDSFile('test')
% bfile.set_entities(entities)

classdef BIDSFile < matlab.mixin.Copyable
    properties (SetAccess = private)
        filename = ''
        dirname = ''
        %tags = ''
        entities = struct
        parent = []
        layout = []
    end
    
    properties 
        fpath = ''
        hash = [];
    end
    
    methods
%         function disp(obj)
%             %fprintf('Class: BIDSFile | Path: %s | Dirname: %s | Filename: %s | Entities: %d\n', obj.fpath, obj.filename, obj.dirname, numel(obj.entities));
%             fprintf('Class: BIDSFile | Path: %s', obj.fpath);
%             fns = fieldnames(obj.entities);
%             
%             if ~isempty(fns)
%                 fprintf(' | Entities: ');
%                 
%                 delim = ' | ';
%                 for i=1:numel(fns)
%                     if i==numel(fns)
%                         delim = '';
%                     end
%                     fprintf('%s: %s%s', fns{i}, num2str(obj.entities.(fns{i})), delim);
%                 end
%             end
%             fprintf('\n');
%         end
        
%         function obj = set.fpath(obj, fpath)
%             obj.fpath =fpath;
%             [obj.dirname, obj.filename, ext] = fileparts(obj.fpath);
%             if ~isempty(ext)
%                 obj.filename = [obj.filename, ext];
%             end
%         end

        % Constructor
        function obj = BIDSFile(filename, varargin)
            %         Args:
            %         filename (str): Full path to file.
            %         parent (BIDSNode): Optional parent node/directory.
            %
            p = inputParser;
            p.StructExpand = true;
            addRequired(p, 'filename',@(x)validateattributes(x,{'char'},{'nonempty'}));
            addOptional(p, 'parent', [], @(x)validateattributes(x,{'BIDSNode'},{'nonempty'}));
            parse(p, filename, varargin{:});
            
            obj.fpath = p.Results.filename;
            
            [obj.dirname, obj.filename, ext] = fileparts(obj.fpath);
            if ~isempty(ext)
                obj.filename = [obj.filename, ext];
            end
            
            obj.parent = p.Results.parent;
            obj.entities = struct;
            obj.hash = string2hash(obj.fpath);
        end
        
        function ent = get_entity(obj, entity)
            if isfield(obj.entities, entity) && ~isempty(obj.entities)
                ent = obj.entities.(entity);
            else
                error('Entity does not exist')
            end
        end
        
        function set_entity(obj, entity, value)
            if isfield(obj.entities, entity)
                obj.entities.(entity) = value;
            else
                error('Entity does not exist')
            end
        end
        
        function set_entities(obj, entities)
            fn = fieldnames(entities);
            for f=1:numel(fn)
                obj.entities.(fn{f}) = entities.(fn{f});
            end
        end
        
        function add_entity(obj, entity, value)
            if isfield(obj.entities, entity)
                error('Entity already exists')
            else
                obj.entities.(entity) = value;
            end
        end
        
        
        %         function varargout = subsref(obj,s)
        %             varargout{1} = [];
        %             if numel(s) == 1
        %                 switch s(1).type
        %                  case '.'
        %                      if isprop(obj, s(1).subs)
        %                          varargout{1} = obj.(s(1).subs);
        %                      else
        %                          if isfield(obj.entities, s(1).subs)
        %                              varargout{1} = obj.entities.(s(1).subs);
        %                          end
        %                      end
        %                  otherwise
        %                      error('Not a valid indexing expression')
        %                 end
        %             else
        %                 [varargout{1:nargout}] = builtin('subsref',obj,s);
        %             end
        %         end
        
        
        function im = image(obj)
            % load image file
            obj.fpath;
            im = [];
        end
        
        function my_metadata = metadata(obj)
            try
                my_metadata = obj.layout.get_metadata(obj.fpath);
            catch
                my_metadata = [];
            end
        end
        
        function my_layout = get.layout(obj)
            try
                my_layout = obj.parent.layout;
            catch
                my_layout = [];
            end
        end

 
 function ismatch = matches(obj, entities, regex_search)
 %function ismatch = matches(obj, varargin)
            % no input parameter checking with inputParser due to overhead
            % fixed number of input arguments to limit overhead
%            tic
%             defaultsvals = {[], false};
%             defaultsval{1:nargin} = varargin;
            
            
%             if nargin
%                 entities = varargin{1};
%             else
%                 entities = [];
%             end
%             
%             if nargin>=2
%                 regex_search = varargin{2};
%             else
%                 regex_search = false;
%             end
            
            fns = fieldnames(entities);
            
            if isempty(fns)
                ismatch = true;
                return
            end
                
            
            %for i=fns' is slower than indexing
            for idx=1:numel(fns)
                name = fns{idx};
                val = entities.(name);
                
                if xor(~isfield(obj.entities, name), isempty(val))
                    ismatch = false;
                    return
                end
                
                if isempty(val)
                    %ismatch = false;
                    continue
                end
                val = cellify(val);
                
                % much faster than cellfun, also more optimized for speed
                 patt = make_patt(val{1}, regex_search);
                 if numel(val)>1
                     for idx2=1:numel(val)
                         patt = [patt, '|', make_patt(val{idx2}, regex_search)];
                     end
                 end
                 %patt(1)='';
                
%                  ent_patts = cellfun(@(x) make_patt(x, regex_search), val, 'uni', false);
%                  patt = strjoin(ent_patts, '|');

                if isempty(regexp(castto(obj.entities.(name), 'char'), patt, 'once'))
                    ismatch = false;
                    return
                end
            end
            ismatch = true;
       end
        
       
       
%       function ismatch = matches(obj, varargin)
%             % no input parameter checking with inputParser due to overhead
% %            tic
% 
%             if nargin
%                 entities = varargin{1};
%             else
%                 entities = [];
%             end
%             
%             if nargin>2
%                 regex_search = varargin{2};
%             else
%                 regex_search = false;
%             end
%             
%             
% %             entities = [];
% %             regex_search = false;
% %             if nargin
% %                 entities = varargin{1};
% %             end
% %             
% %             if nargin>2
% %                 regex_search = varargin{2};
% %             end
% 
%             fns = fieldnames(entities);
%             
%             if isempty(fns)
%                 ismatch = true;
%                 return
%             end
%             
%             
%             for name_ = fns'
%                 name = name_{1};
%                 val = entities.(name);
%                 
%                 if xor(~isfield(obj.entities, name), isempty(val))
%                     ismatch = false;
%                     return
%                 end
%                 
%                 if isempty(val)
%                     ismatch = false;
%                     continue
%                 end
%                 
%                 val = cellify(val);
%                 
%                 ent_patts = cellfun(@(x) make_patt(x, regex_search), val, 'uni', false);
%                 patt = strjoin(ent_patts, '|');
% 
%                 %cast = castto(obj.entities.(name), 'char');
% 
%                 if isempty(regexp(castto(obj.entities.(name), 'char'), patt, 'once'))
%                     ismatch = false;
%                     return
%                 end
%             end
%             ismatch = true;
%        end 
%        
       
       
       
       
       
       
       
       
%         function ismatch = matches(obj, varargin)
% %             tic
% %             p = inputParser;
% %             addOptional(p, 'entities', [], @(x)validateattributes(x,{'struct'},{}));
% %             %addOptional(p, 'extensions', {}, @(x)validateattributes(x,{'cell', 'char'},{}));
% %             addOptional(p, 'regex_search', false, @(x)validateattributes(x,{'logical', 'double'},{'nonempty'}));
% %             parse(p, varargin{:});
% %             %extensions = cellify(p.Results.extensions);
% %             entities = p.Results.entities;
% %             regex_search = logical(p.Results.regex_search);
% %            ismatch = true;
% %             toc
%             
%             % no input parameter checking with inputParser due to overhead
% %            tic
%             entities = [];
%             regex_search = false;
%             ismatch = true;
%             if nargin
%                 entities = varargin{1};
%             end
%             
%             if nargin>2
%                 regex_search = varargin{2};
%             end
%  %           toc
% 
%             
%             %             if ~isempty(extensions)
% %                 extensions = cellfun(@(x) regex_escstr(x), extensions, 'uni', false);
% %                 extensions = strjoin(extensions, '|');
% %                 % small bug in pybids: add . to extensions list regular
% %                 % expression
% %                 extensions = strjoin({'.(', extensions, ')$'}, '');
% %                 
% %                 extfound = regexp(obj.filename, extensions, 'once');
% %                 
% %                 if isempty(extfound)
% %                     ismatch = false;
% %                     return
% % 
% %                 end
% %             end
%  
%             if isempty(fieldnames(entities))
%                 ismatch = true;
%                 return
%             end
% %               moved to separate function, performance speed        
% %             function patt = make_patt_(x)
% %                 patt = castto(x, 'char');
% %                 
% %                 if ~regex_search
% %                     patt = regex_escstr(patt);
% %                 end
% %                 
% %                 if isa(x, 'numeric')
% %                     patt = strcat('0*', patt);
% %                 end
% %                 
% %                 if ~regex_search
% %                     patt = strcat('^', patt, '$');
% %                 end
% %             end
% 
%             fn = fieldnames(entities);
%             for i = 1:numel(fieldnames(entities))
%                 name = fn{i};
%                 val = entities.(name);
%                 %disp(sprintf('testing for %s = %s', name, castto(val, 'char')))
%                 
%                 if xor(~isfield(obj.entities, name), isempty(val))
%                     ismatch = false;
%                     return
%                 end
%                 
%                 if isempty(val)
%                     ismatch = false;
%                     continue
%                 end
% 
%                 val = cellify(val);
%                 % ent_patts = cellfun(@(x) make_patt_(x), val, 'uni', false);
%                 ent_patts = cellfun(@(x) make_patt(x, regex_search), val, 'uni', false);
%                 patt = strjoin(ent_patts, '|');
% 
%                 cast = castto(obj.entities.(name), 'char');
% 
%                 if isempty(regexp(castto(obj.entities.(name), 'char'), patt, 'once'))
%                     ismatch = false;
%                     return
%                 end
%             end
%             ismatch = true;
%        
%         end
        
        function copyfile(obj, path_patterns, varargin)
            % different name as in pybids to allow inheritance from
            % matlab.mixin.Copyable
            % Copy the contents of a file to a new location.
            % Seems to be a bug in pybids where new_filename 
            % Mainly rewritten
            %
            % Args:
            %     path_patterns (list): List of patterns use to construct the new
            %         filename. See build_path documentation for details.
            %     symbolic_link (bool): If True, use a symbolic link to point to the
            %         existing file. If False, creates a new file.
            %     root (str): Optional path to prepend to the constructed filename.
            %                 If path of file is already absolute, root
            %                 will be discarded.
            %     conflicts (str): Defines the desired action when the output path
            %         already exists. Must be one of:
            %             'fail': raises an exception
            %             'skip' does nothing
            %             'overwrite': overwrites the existing file
            %             'append': adds  a suffix to each file copy, starting with 1
        
            p = inputParser;
            
            conflict_vals = {'fail', 'skip', 'overwrite', 'append'};
            addRequired(p, 'path_patterns',@(x)validateattributes(x,{'cell'},{}));
            addOptional(p, 'symbolic_link', false, @(x)validateattributes(x,{'logical', 'double'},{'nonempty'}));
            addOptional(p, 'root', '', @(x)validateattributes(x,{'char'},{}));
            addOptional(p, 'conflicts', 'fail', @(x) any(validatestring(x,conflict_vals)));
            parse(p, path_patterns, varargin{:});

    %     Args:
    %         path (str): Destination path of the desired contents.
    %         contents (str): Raw text or binary encoded string of contents to write
    %             to the new path.
    %         link_to (str): Optional path with which to create a symbolic link to.
    %             Used as an alternative to and takes priority over the contents
    %             argument.UNSUPPORTED
    %         content_mode (str): Either 'text' or 'binary' to indicate the writing
    %             mode for the new file. Only relevant if contents is provided.
    %         root (str): Optional root directory that all patterns are relative
    %             to. Defaults to current working directory.
    %         conflicts (str): One of 'fail', 'skip', 'overwrite', or 'append'
    %             that defines the desired action when the output path already
    %             exists. 'fail' raises an exception; 'skip' does nothing;
    %             'overwrite' overwrites the existing file; 'append' adds  a suffix
    %             to each file copy, starting with 1. Default is 'fail'.
    %     """
    
            symbolic_link = p.Results.symbolic_link;
            root = p.Results.root;
            conflicts = p.Results.conflicts;
          
            new_filename = build_path(obj.entities, path_patterns);
            if isempty(new_filename)
                return
            end
                        
            if isabs(obj.fpath)
                fpath = obj.fpath;
            else
                fpath = fullfile(obj.dirname, obj.filename);
            end
            
            % disable symbolic link from pybids
            symbolic_link = false;
            %%%
            if symbolic_link
                contents = '';
                link_to = fpath;
            else
                %read contents from fpath
                try
                    contents = fileread(fpath);
                catch ME
                    error(ME.message);
                end
                link_to = '';
            end
            
              write_contents_to_file(new_filename, contents, ...
                  'link_to', link_to, 'content_mode', 'text', ...
                  'root', root,'conflicts', conflicts);
        end
    end
end