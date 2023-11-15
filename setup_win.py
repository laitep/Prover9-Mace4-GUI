import pathlib
import sys
from collections import defaultdict
from py2exe import freeze

parent = pathlib.Path(__file__).parent
src = parent.joinpath("src")
# This makes sure the other Python scripts are found and bundled.
sys.path.insert(0, src.as_posix())

data_files = [
    ("bin", src.joinpath("bin").glob("*")),
    ("Images", src.joinpath("Images").glob("*")),
]
samples = src.joinpath("Samples")
files = defaultdict(list)
for sample in samples.glob("**/*.in"):
    bundle_path = sample.parent.as_posix()[len(samples.parent.as_posix()) + 1 :]
    files[bundle_path].append(sample)
for bundle_path, file_list in files.items():
    data_files.append((bundle_path, file_list))

freeze(
    windows=[
        {
            "script": src.joinpath("prover9-mace4.py").as_posix(),
            "icon_resources": [(1, parent.joinpath("p9-48.ico").as_posix())],
        }
    ],
    data_files=data_files,
    options={
        "dist_dir": parent.joinpath("dist").as_posix(),
    },
)
