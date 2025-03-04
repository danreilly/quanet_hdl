% testing class
%
% Functions related to NuCrypt's style of testing & calibration,
% in which data files are saved in device-specific archives.
% All data files are text files in matlab-style assignment syntax,
% as generated by vars_class.  The name of every file is:
%
%     archive/<dev_name>_<sernum>/d<date>/<filetype>_<tstnum>.txt
%
% Calibration files and report files are generated from these files.
% Typically they conain a big matrix in a variable named "data", and
% a space-separated string that is the header for each column of the
% matrix in "data_hdr".
%
% Nucrypt's test and calibration utilities typically prompt for many
% values to customize each test or analysis.  Each time this is done,
% the value is saved in a vars_class file here called "tvars".
% This allows prior values to be used as defaults; you just hit enter.
% We always store the path to the most recently generated datafile
% in our "tvars" file in the variable "data_file".

classdef testing_class < handle

  % instance members
  properties
    tvars
    archive_path % full path to archive

    % or store devinfo?
    dev_name
    sernum

    datafile_path    % just the path of the datafile
    datafile_fname  % full fname including path
    datafile_tstnum % numeric portion of datafile name
    datafile_filetype
  end
  
  properties (Constant=true)
    JUNK=0; % access this to avoid a core dump!
  end

  methods
    
    % CONSTRUCTOR
    function me = testing_class(tvars, arch_name, devinfo)
    % desc: asks if you want to use prior archive, or browse to a new one.      
    % returns: the full path to an archive
      import nc.*
      me.tvars = tvars;
      me.dev_name = devinfo.name;
      me.sernum = devinfo.sn;
      if (isempty(devinfo.sn))
        fprintf('WARN: device has no serial number\n');
        nc.uio.pause();
      end
      if (isempty(devinfo.sn)||(lower(devinfo.sn(1)=='x')))
        fprintf('WARN: device has a temporary serial number (because it begins with x)\n');
        nc.uio.pause();
      end
      
      archive_var = [arch_name '_archive'];
      % fprintf('DBG: archive var %s\n', archive_var);
      while(1)
        tvars.get(archive_var);
        archive = tvars.ask_dir(['calibration archive for ' me.dev_name], archive_var);
        [f_path f_name f_ext]=fileparts(archive);
        if (~strfind(f_name,'archive'));
          fprintf('WARN: %s\n', archive);
          fprintf('      is a non-standard calibration archive name\n');
        end
        if (exist(archive, 'dir'))
          break;
        end
        fprintf('WARN: %s\n', archive);
        fprintf('      doesnt exist\n');
      end
      me.archive_path = archive;
    end


    function v = new_vars(me, filetype, fname, dev)
      import nc.*
      datafile_fname = next_datafile(me, filetype, fname);
      fprintf('will create:\n');
      uio.print_all(datafile_fname);
      v = vars_class(datafile_fname);
      v.set('filetype', filetype);
      v.set('tstnum', me.datafile_tstnum);
      v.set_context(dev);
      me.ensure_datafile_path();
    end
    
    function datafile_fname = next_datafile(me, filetype, fname)
    % desc: figures out a unique filename for the next datfile to produce.      
    %       However, it does not create the file yet.
    % returns: full filename (including path) to the next datafile       
      import nc.*
      me.datafile_filetype=filetype;
      pname=fullfile(me.archive_path, [me.dev_name '_' lower(me.sernum)], ['d' datestr(now,'yymmdd')]);
      [tstname tstnum] = fileutils.uniquename(pname, fname);

      me.datafile_tstnum = tstnum;
      datafile_fname = fullfile(pname, tstname);
      me.datafile_path = pname;
      me.datafile_fname = datafile_fname;
      me.tvars.set('data_file', datafile_fname)
    end

    function ensure_datafile_path(me)
      import nc.*
      fileutils.ensure_dir(me.datafile_path);
    end
    
  end
end
