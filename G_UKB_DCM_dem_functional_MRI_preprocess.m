% Code written by Gabe Yawitch (zcemgmy@ucl.ac.uk) - last updated 19/3/25
% Adapted from https://github.com/Wolfson-PNU-QMUL/UKB_DCM_dementia
% Which is adapted from Almgren et al. https://github.com/halmgren/Pipeline_preprint_variability_reliability_DCM_rsfMRI
% This code pre-processes the UKB rs-fmri data
% No slice timing correction needed due to short TR (multiband sequence)

function G_UKB_DCM_dem_functional_MRI_preprocess(subjects, datadir, maxFD)

    spm('Defaults','fMRI')

for subject_id = 1:numel(subjects)
    tic
    EID = subjects(isj);
    matlabbatch=[];

    fprintf(['Running functional preprocessing for subject: ' num2str(EID) ' (' num2str(subject_id) ' of ' num2str(numel(subjects)) ')\n'])

    %add this subject's data to the search path
    struct_data_path = [datadir num2str(EID) '/ses-1/anat/'];
    funct_data_path = [datadir num2str(EID) '/ses-1/func/'];
    addpath(struct_data_path);
    addpath(funct_data_path);

    %skip if subject already pre-processed
    if exist([funct_data_path 'swr_rfMRI.nii'])>0
        fprintf('Done already - skipping...\n')
        continue
    end

    %skip if subject partially pre-processed and already aborted due to
    %high motion
    regressors_directory = [funct_data_path 'regressors/'];
    if exist([regressors_directory 'Framewise_Displacement.mat'])
        load([regressors_directory 'Framewise_Displacement.mat']);
        if max(FD)>maxFD
            clear FD
            continue
        end
    end

    %Try realigning using single-band reference scan.
    %If framewise displacement is >2.4 mm then re-try using mean EPI
    %instead
    % If framewise displacement is still >2.4 mm then abort preprocessing
    % and exclude subject
    realigning =1;
    SBREF = 1;
    while realigning
        %Label data files
        zipped_func_file = [funct_data_path '*bold.nii.gz'];
        rfMRI_file = gunzip(zipped_func_file);
        
        % For now I will just use the mean functional image as the reference
        % image for realignment.
        SBREF = 0;
        % if SBREF ==1
        %     zipped_T1w_reference_scan = [struct_data_path '*T1w.nii'];
        %     T1w_reference_scan = gunzip(zipped_T1w_reference_scan);
        %     %Realign to T1w reference image
        %     data = {[T1w_reference_scan;(cellstr(spm_select('expand',rfMRI_file)))]};
        
        % This line is...
        %elsif SBREF == 0
        if SBREF == 0
            functional_reference_scan = [funct_data_path 'meanrfMRI.nii'];
            %Don't realign to single-band reference image
            data = {[functional_reference_scan;(cellstr(spm_select('expand',rfMRI_file)))]};
        end
            
        % I don't think this file exists.
        structural_reference_scan = [struct_data_path '/T1/UKBDCM_PreProc/Skullstr_biascor_structural.nii,1'];


        %%%%%%%%%%%%%%%%%%%%%%%
        %Spatial realignment
        %%%%%%%%%%%%%%%%%%%%%%%
        matlabbatch{1}.spm.spatial.realign.estwrite.data = data;
        matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.quality = 0.9;
        matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.sep = 4;
        matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.fwhm = 5;
        matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.rtm = 0;
        matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.interp = 2;
        matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.wrap = [0 0 0];
        matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.weight = '';
        matlabbatch{1}.spm.spatial.realign.estwrite.roptions.which = [2 1];
        matlabbatch{1}.spm.spatial.realign.estwrite.roptions.interp = 4;
        matlabbatch{1}.spm.spatial.realign.estwrite.roptions.wrap = [0 0 0];
        matlabbatch{1}.spm.spatial.realign.estwrite.roptions.mask = 1;
        matlabbatch{1}.spm.spatial.realign.estwrite.roptions.prefix = 'r';

        spm_jobman('run',matlabbatch);
        clear matlabbatch


        



end

