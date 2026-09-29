# Passive Dual-Layer EEG

This repository contains the analysis code and supporting resources for a study investigating whether dual-layer EEG technology improves signal quality in a passive-electrode system during mobile EEG recordings.

Mobile EEG recordings can be affected by motion artifacts, particularly during physical activity. Dual-layer electrode systems have been suggested as a potential approach for improving artifact correction. In this study, we investigated whether similar benefits could be obtained with a lightweight, head-mounted wireless EEG amplifier using passive electrodes.

The study consisted of two parts:

1) EEG phantom-head experiment
An EEG phantom head with known signal sources was combined with a 3D motion platform. We investigated whether the iCanClean algorithm, using signals from a dual-layer electrode configuration, improved recovery of simulated brain signals compared with a conventional single-layer preprocessing pipeline.
2) Mobile EEG experiment
EEG data were collected from 15 participants freely walking outdoors during a cognitive–motor dual-task paradigm. Two preprocessing pipelines were compared: one incorporating the second electrode layer for artifact correction using iCanClean, and one using only the primary EEG layer.

Overall, the analyses did not provide evidence for a clear benefit of the dual-layer approach with iCanClean in this passive-electrode system. In the phantom-head experiment, imperfect isolation between the phantom head and second-layer electrode signals may have resulted in overcorrection. In the mobile EEG experiment, the relatively modest presence of motion artifacts may have limited the potential benefit of the dual-layer approach.

## Reopsitory Structure

passive_duallayer_EEG/
├── scripts/
│ ├── participants/ # Analysis scripts for the mobile EEG experiment
│ ├── phantom_head/ # Analysis scripts for the phantom-head experiment
│ ├── statistical_analysis/ # Analysis scripts for the statistical evaluation of both experiments
│ └── functions/ # Supporting MATLAB functions
├── resources/ # Electrode and head-model resources
├── participant_info.xlsx 
├── measurement_info.xlsx 
└── README.md

## Analysis workflow
The analysis scripts are organized according to the two experimental parts of the study.

### Phantom-head experiment
Scripts in scripts/phantom_head/ implement the preprocessing and analysis of the phantom-head recordings, including data checking, artifact correction, ICA, epoching, ERP analysis, and related processing steps.

### Mobile EEG experiment
Scripts in scripts/participants/ implement the preprocessing and analysis of the participant recordings, including data checking, artifact correction, ICA, epoching, ERP analysis, gait-related processing, and time–frequency analyses.
Reusable MATLAB functions required by the analysis are located in scripts/functions/.

## Requirements
- MATLAB R2025a
- EEGLAB
- iCanClean plugin
- loadxdf plugin
- Python 3.11

## How to use
Edit and run the main script in `scripts/`, adjusting parameters as needed.

## Reference

This repository accompanies the associated research publication.

Citation: To be added once the final publication details are available.

## License

License information will be added to this repository.

## Contact

For questions regarding the analysis code or repository, please contact the authors of the associated publication.
