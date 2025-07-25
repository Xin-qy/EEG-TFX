function [foldData, foldLabel] = process_from_zip(folder_path, xlsx_file, fs_raw, notch_freq, bp_order, fold_num, use_notch, use_bp, f_pass, f_stop)
%It is used to process the EEG.txt file + tag.xlsx file → into foldData/foldLabel
% Input:
% folder_path - EEG txt folder path
% xlsx_file - Tag file path
% fs_raw - original sampling rate (e.g. 1000)
% notch_freq-notch frequency (50 or 60)
% bp_order - Bandpass filter order (2 or 3)
% fold_num - number of folds (e.g. 5)
% use_notch - Whether to use the Notch filter
% use_bp - Whether to use the Bandpass filter

    fs_target = 250; 

    label_table = readtable(xlsx_file);

    eeg_files = dir(fullfile(folder_path, '*.txt'));
    num_files = length(eeg_files);
    if fold_num > num_files
        error('❌ The number of folds cannot exceed the number of samples');
    end

    if use_notch
        d_notch = designfilt('bandstopiir', 'FilterOrder', 2, ...
            'HalfPowerFrequency1', notch_freq - 1, ...
            'HalfPowerFrequency2', notch_freq + 1, ...
            'SampleRate', fs_raw);
    end

    if use_bp
          [b_bp, a_bp] = butter(bp_order, [f_pass f_stop]/(fs_raw/2), 'bandpass');
    end

    data_list = cell(1, num_files);
    label_list = cell(1, num_files);

    for i = 1:num_files
        raw = load(fullfile(folder_path, eeg_files(i).name));
        if size(raw, 1) < size(raw, 2)
            raw = raw';  
        end

        if use_notch
            raw = filtfilt(d_notch, raw);
        end
        if use_bp
            raw = filtfilt(b_bp, a_bp, raw);
        end

        raw = raw';  

        [nch, orig_len] = size(raw);
        new_len = round(orig_len * fs_target / fs_raw);
        resampled = zeros(nch, new_len);
        for ch = 1:nch
            resampled(ch,:) = resample(raw(ch,:), fs_target, fs_raw);
        end
        raw = resampled;

        [~, name, ~] = fileparts(eeg_files(i).name);
        idx = find(strcmpi(label_table{:,1}, name));
        if isempty(idx)
            warning('The label was not found.：%s', name);
            lbl = NaN;
        else
            lbl = label_table{idx,2};
        end

        data_list{i} = raw;
        label_list{i} = lbl;
    end

    rng(1);
    perm = randperm(num_files);
    fold_size = floor(num_files / fold_num);
    foldData = cell(1, fold_num);
    foldLabel = cell(1, fold_num);

    for k = 1:fold_num
        if k < fold_num
            idx = perm((k-1)*fold_size+1 : k*fold_size);
        else
            idx = perm((k-1)*fold_size+1 : num_files);
        end

        nsample = numel(idx);
        nch = size(data_list{idx(1)}, 1);
        ns = size(data_list{idx(1)}, 2);
        temp_data = zeros(nsample, nch, ns);
        temp_label = zeros(nsample, 1);

        for j = 1:nsample
            temp_data(j,:,:) = data_list{idx(j)};
            temp_label(j) = label_list{idx(j)};
        end

        foldData{k} = temp_data;
        foldLabel{k} = temp_label;
    end
end
