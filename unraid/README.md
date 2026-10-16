# Unraid Community Applications templates

Ready-to-use Unraid Docker templates for this fork of the AI model server.

| Template | Image tag | GPU |
| --- | --- | --- |
| `media-ai-model-server.xml` | `latest` (`cuda`) | NVIDIA (CUDA) |
| `media-ai-model-server-amd.xml` | `amd` | AMD (ROCm) |
| `media-ai-model-server-intel.xml` | `intel` | Intel (XPU) |

The NVIDIA image is tuned for a **Tesla M40 24GB** (`sm_52`, CUDA 12.6
wheels). Other CUDA cards, in particular newer ones that expect CUDA 13.x,
may not work with this image.

## Install

### Option A - add this repository to Community Applications

1. Unraid **Apps** tab -> **Settings** (or *Docker* -> *Template Repositories*).
2. Add a repository pointing at the `unraid` folder of this repo:
   `https://github.com/binarygeek119/media_ai_model_server`
   (the templates live in `unraid/*.xml`).
3. Open **Apps**, search for *Media AI Model Server* and install the variant
   matching your GPU.

### Option B - drop the template file onto the server

Copy the desired XML into `/boot/config/plugins/dockerMan/templates-user/`
on the Unraid box, then use **Docker -> Add Container -> Template**.

## GPU prerequisites

- **NVIDIA:** install the **Nvidia-Driver** plugin so the `nvidia` runtime is
  available. The template already passes `--runtime=nvidia` and sets
  `NVIDIA_VISIBLE_DEVICES=all` / `NVIDIA_DRIVER_CAPABILITIES=compute,utility,video`.
- **AMD:** the ROCm kernel driver must be available on the host. `/dev/kfd` and
  `/dev/dri` are passed through.
- **Intel:** an Intel Arc/integrated GPU with the i915/xe driver. `/dev/dri` is
  passed through.

## After install

The image contains the server but **no AI models**. On first run the container
seeds a default `config` into the mounted Config path, then you add models:

1. Download the free or paid models from the project wiki
   (<https://github.com/skier233/nsfw_ai_model_server/wiki/AI-Models>).
2. Unzip and copy the `config` and `models` folders into the mounted paths:
   - `/mnt/user/appdata/media-ai-model-server/config`
   - `/mnt/user/appdata/media-ai-model-server/models`
3. Add the model name(s) to `config/active_ai.yaml`, or change models at
   runtime through the client (Settings -> Extensions -> AI).
4. If a model is subscriber-only, save the generated `.lic` license file into
   the Models path.

The API listens on port `8000`; interactive docs are at
`http://<unraid-ip>:8000/docs`.

## Volumes

| Container path | Purpose |
| --- | --- |
| `/app/config` | Persistent config, pipeline selection and downloaded model YAMLs |
| `/app/models` | Downloaded model files and license files |
| `/media` | Your media library (paths sent to the API must resolve here) |
