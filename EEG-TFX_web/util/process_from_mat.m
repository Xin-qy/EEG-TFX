function [foldData, foldLabel] = process_from_mat(rawData, rawLabel, fs_raw, notch_freq, bp_order, use_notch, use_bp, f_pass, f_stop)
% rawData: cell, each cell is [number of samples × number of channels × number of sampling points]
% rawLabel: cell, each cell is [number of samples × 1]
% fs_raw: Original sampling rate
% notch_freq: Center frequency of the band-stop filter
% bp_order: The order of the bandpass filter
% use_notch: Whether to enable the band-stop filter
% use_bp: Whether to enable the bandpass filter
% f_pass: The low-frequency cut-off frequency of the bandpass filter
% f_stop: The high-frequency cut-off frequency of the bandpass filter

    fs_target = 250;

    fold_num = length(rawData);
    foldData = cell(1, fold_num);
    foldLabel = rawLabel;

    if use_notch
        d_notch = designfilt('bandstopiir', 'FilterOrder', 2, ...
            'HalfPowerFrequency1', notch_freq - 1, ...
            'HalfPowerFrequency2', notch_freq + 1, ...
            'SampleRate', fs_raw);
    end

    if use_bp
        [b_bp, a_bp] = butter(bp_order, [f_pass f_stop]/(fs_raw/2), 'bandpass');
    end

    for k = 1:fold_num
        data = rawData{k}; 
        nsample = size(data, 1);
        nch = size(data, 2);
        npoint = size(data, 3);

        new_point = round(npoint * fs_target / fs_raw);
        temp_data = zeros(nsample, nch, new_point);

        for i = 1:nsample
            eeg = squeeze(data(i, :, :));  

            if use_notch
                eeg = filtfilt(d_notch, eeg')';  
            end
            if use_bp
                eeg = filtfilt(b_bp, a_bp, eeg')';  
            end

            resampled = zeros(nch, new_point);
            for ch = 1:nch
                resampled(ch,:) = resample(eeg(ch,:), fs_target, fs_raw);
            end

            temp_data(i,:,:) = resampled;
        end

        foldData{k} = temp_data;
    end
end