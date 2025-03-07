{
  lib,
  stdenv,
  buildPythonPackage,
  fetchFromGitHub,
  rustPlatform,

  # nativeBuildInputs
  pkg-config,

  # buildInputs
  libiconv,
  openssl,
  protobuf,
  darwin,

  # dependencies
  numpy,
  pyarrow,

  # optional-dependencies
  torch,

  # tests
  duckdb,
  ml-dtypes,
  pandas,
  pillow,
  polars,
  pytestCheckHook,
  tqdm,

  # passthru
  nix-update-script,
}:

buildPythonPackage rec {
  pname = "pylance";
  version = "0.22.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "lancedb";
    repo = "lance";
    tag = "v${version}";
    hash = "sha256-UOrkVHgTX1JK6chYJ6I+VJUquwsKLnOI5solS9W21HY=";
  };

  sourceRoot = "${src.name}/python";

  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit
      pname
      version
      src
      sourceRoot
      ;
    hash = "sha256-D9+rKV4rF5AVMxFfEohHufHC2mO75M80TuZaHDI0XMU=";
  };

  nativeBuildInputs = [
    pkg-config
    protobuf # for protoc
    rustPlatform.cargoSetupHook
  ];

  build-system = [
    rustPlatform.cargoSetupHook
    rustPlatform.maturinBuildHook
  ];

  buildInputs =
    [
      libiconv
      openssl
      protobuf
    ]
    ++ lib.optionals stdenv.hostPlatform.isDarwin (
      with darwin.apple_sdk.frameworks;
      [
        Security
        SystemConfiguration
      ]
    );

  pythonRelaxDeps = [ "pyarrow" ];

  dependencies = [
    numpy
    pyarrow
  ];

  optional-dependencies = {
    torch = [ torch ];
  };

  pythonImportsCheck = [ "lance" ];

  nativeCheckInputs = [
    duckdb
    ml-dtypes
    pandas
    pillow
    polars
    pytestCheckHook
    tqdm
  ] ++ optional-dependencies.torch;

  preCheck = ''
    cd python/tests
  '';

  disabledTests =
    lib.optionals stdenv.hostPlatform.isDarwin [
      # AttributeError: module 'torch.distributed' has no attribute 'is_initialized'
      "test_convert_int_tensors"
      "test_ground_truth"
      "test_index_cast_centroids"
      "test_index_with_no_centroid_movement"
      "test_iter_filter"
      "test_iter_over_dataset_fixed_shape_tensor"
      "test_iter_over_dataset_fixed_size_lists"
    ]
    ++ [
      # incompatible with duckdb 1.1.1
      "test_duckdb_pushdown_extension_types"
      # Writes to read-only build directory
      "test_add_data_storage_version"
      "test_fix_data_storage_version"
    ];

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Python wrapper for Lance columnar format";
    homepage = "https://github.com/lancedb/lance";
    changelog = "https://github.com/lancedb/lance/releases/tag/v${version}";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ natsukium ];
    # test_indices.py ...sss.Fatal Python error: Fatal Python error: Illegal instructionIllegal instruction
    # File "/nix/store/wiiccrs0vd1qbh4j6ki9p40xmamsjix3-python3.12-pylance-0.17.0/lib/python3.12/site-packages/lance/indices.py", line 237 in train_ivf
    broken = stdenv.hostPlatform.isDarwin && stdenv.hostPlatform.isx86_64;
  };
}
