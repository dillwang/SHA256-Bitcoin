#SHA-256 and Bitcoin Hashing Implementation

## Project Overview

This project explores the implementation and optimization of the **SHA-256 cryptographic hash function** and its application in **Bitcoin hashing** using **SystemVerilog**.

## Table of Contents
- [Project Overview](#project-overview)
- [SHA-256 Overview](#sha-256-overview)
- [Bitcoin Hashing Overview](#bitcoin-hashing-overview)
- [Implementation Details](#implementation-details)
  - [SHA-256 Algorithm](#sha-256-algorithm)
  - [Bitcoin Hashing Algorithm](#bitcoin-hashing-algorithm)
- [Optimizations](#optimizations)
- [Snapshots and Reports](#snapshots-and-reports)
- [Resource Usage and Performance](#resource-usage-and-performance)

## SHA-256 Overview

**SHA-256 (Secure Hash Algorithm 256-bit)** is a cryptographic hash function widely used in security applications and blockchain technology. 

Key features:
- **Compression:** Produces fixed-length 256-bit hashes regardless of input size.
- **Avalanche Effect:** Small input changes yield large output changes.
- **Deterministic:** Identical inputs produce identical outputs.
- **Preimage Resistant:** The original input cannot be deduced from the hash.
- **Collision Resistant:** Difficult for two inputs to result in the same hash.

## Bitcoin Hashing Overview

Bitcoin mining leverages **SHA-256** to solve cryptographic puzzles by finding a hash meeting specific criteria, such as starting with a specified number of zeros. The process involves:
- Appending a nonce to input data.
- Iteratively hashing until a valid hash is found.

## Implementation Details

### SHA-256 Algorithm

- **Input:** Divided into 512-bit blocks.
- **Processing:** Each block undergoes 64 rounds of compression using pre-defined constants and message expansion.
- **Output:** A final 256-bit hash.

#### SystemVerilog Implementation
- **Finite State Machine (FSM):**
  - States include `IDLE`, `WAIT`, `READ`, `BLOCK`, `COMPUTE`, `WRITE`, and `INCREMENT`.
- **Key Functions:**
  - **sha256_op:** Performs a single round of compression.
  - **wtnew:** Computes expanded message words.
  - **Optimized Memory Usage:** Reduced from 64 to 16 memory units for expanded words.

### Bitcoin Hashing Algorithm

- **Parallel SHA-256 Modules:**
  - Multiple modules instantiated using a generate loop for nonce-based parallel processing.
- **FSM:** Handles transitions across states for reading, hashing, and writing results.
- **Three-Phase Hashing:**
  - Phase 1: Initial block hashing.
  - Phase 2: Second block preparation and hashing.
  - Phase 3: Third block hashing and final output.

## Optimizations

1. **SHA-256 Optimization:**
   - Reduced word memory requirements for message expansion, cutting cycles from ~4000 to 175.
2. **Bitcoin Hashing Optimization:**
   - Parallelization of 16 SHA-256 modules, significantly accelerating nonce exploration.

## Snapshots and Reports

### SHA-256
- Waveforms and Transcript
- FMax Report
- Resource Usage

### Bitcoin Hashing
- Waveforms and Transcript
- FMax Report
- Resource Usage

## Resource Usage and Performance
- **SHA-256:** Optimized to minimize memory usage and computational cycles.
- **Bitcoin Hasher:** Parallelized modules and optimized FSM, reducing the hashing process to minimal cycles.
