# IST Computational Vision Project

This repository contains the coursework and projects for the Instituto Superior Técnico **Computational Vision** course.

## Authors

- David Marafuz Gaspar - 106541
- Pedro Gaspar Mónico - 106626

## Project Overview

The repository is organized into **course laboratories** (weekly MATLAB exercises) and **two main projects**, each addressing a different computer vision problem:

- **Project 1**: Classical vision pipeline for **railway track / obstacle reasoning** (preprocessing, Hough-based rail cues, region splits, superpixel anomaly cues, and classification against ground truth).
- **Project 2**: **Thermal image object detection** using deep learning (YOLO-style detectors with transfer learning, person vs. vehicle, optional comparison with RGB).

## Repository Structure

```
ist-computational-vision-project/
├── Laboratories/                 # Course lab scripts (MATLAB)
│   ├── Lab 1/
│   ├── Lab 2/
│   ├── …
│   └── Lab 10/
│
├── Projects/
│   ├── Project 1/                # Railway / obstacle vision pipeline
│   │   ├── Deliverable/          # Submission-ready functions & plots
│   │   │   ├── Data/             # Images and assets used by the pipeline
│   │   │   ├── aux_*.m           # Core steps (checkpoint, rails, regions, outliers, classification)
│   │   │   └── plot_*.m          # Optional visualization helpers
│   │   ├── Development - David/
│   │   ├── Development - Pedro/
│   │   └── Papers/               # Reference papers
│   │
│   └── Project 2/                # Thermal object detection (deep learning)
│       ├── Deliverable/          # Training scripts, auxiliaries, outputs
│       │   ├── Data/             # COCO-style thermal subsets
│       │   └── Output/           # Training logs, metrics, detections
│       ├── Development - David/
│       └── Development - Pedro/
│
└── README.md                     # This file
```

## Project 1 — Railway Track Pipeline

**Location**: [`Projects/Project 1/`](Projects/Project%201/)

End-to-end **MATLAB** pipeline on monocular rail images: enhancement and binarization (CLAHE, DoG, Otsu), ROI masking, Hough-based strip metrics for an initial **Clear / Obstructed** decision, polynomial **rail regression** on cleared images, **three-way** left / middle / right regions, **superpixel** outlier maps, and **anomaly ratios** fused with a threshold for a final **final_status** vs. labels.

**Key features**:

- Reusable `aux_*` functions for each report section (checkpointing, rail fit, regions, superpixels, anomaly classification).
- `aux_checkpoint.m` loads data and reproduces preprocessing and initial classification without heavy plotting.
- Optional `plot_*.m` scripts for figures in the report.
- Ground-truth labels and development experiments live under each `Development - */` folder.

## Project 2 — Thermal Object Detection

**Location**: [`Projects/Project 2/`](Projects/Project%202/)

**MATLAB** object detection on **thermal** imagery using transfer learning (e.g. YOLOv2 with SqueezeNet / GoogLeNet-style workflows), **two classes** (person, vehicle), COCO-style annotations, training/validation/test splits, and evaluation outputs (metrics, PR curves, sample detections). Additional scripts compare or improve baselines (e.g. `aux_compare_with_rgb.m`, improved model variants).

**Key features**:

- Baseline and improved training scripts in `Deliverable/`.
- Auxiliary helpers for dataset handling and evaluation.
- Large outputs under `Deliverable/Output/` (training curves, JSON summaries, CSV metrics).

## Requirements

- **MATLAB** (version used in course labs; Image Processing Toolbox and Deep Learning Toolbox as needed for the project scripts).
- **Linux** (optional): for OpenGL-related MATLAB issues, the project may use:

- No Python environment is required for the core repository layout above; individual scripts may assume MATLAB add-ons listed in the course documentation.

## Development Process

1. **Data & ground truth** — Images, ROI definitions, and labels prepared under each project’s `Development - */` and `Deliverable/Data/`.
2. **Classical pipeline (Project 1)** — Preprocessing → segmentation cues → Hough / region / superpixel features → rule-based and thresholded fusion.
3. **Deep learning (Project 2)** — Data loading from COCO, anchor-based detector training, validation, and test evaluation.
4. **Visualization & reporting** — Plots and tables exported from MATLAB; deliverable functions kept minimal and reproducible.

## Deliverables

- **Project 1**: Modular `aux_*.m` and optional `plot_*.m` under [`Projects/Project 1/Deliverable/`](Projects/Project%201/Deliverable/), plus data under `Deliverable/Data/` (paths relative to the working directory when running scripts).
- **Project 2**: Training and evaluation scripts under [`Projects/Project 2/Deliverable/`](Projects/Project%202/Deliverable/), with `Output/` containing run artifacts (not all required for a minimal submission—see project brief).

## Documentation

- This README is the top-level overview.
- For deeper detail, see **reports** and **course handouts** as specified in the Computational Vision syllabus; project-specific notes may live alongside the code in each `Development - */` folder.

## Important Notes

- Run MATLAB with the **current folder** set to the relevant `Deliverable/` (or as indicated in each script) so relative paths to `./Data/` resolve correctly.
- `Projects/Project 1/Deliverable/` and `Projects/Project 2/Deliverable/` are intended to stay **self-contained** for submission; heavy development runs remain in `Development - */`.
- Laboratory folders under `Laboratories/` are independent and used for weekly exercises.

---

*This is a IST Computational Vision course assignment for the academic year 2025–2026.*
