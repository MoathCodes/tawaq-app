# Linux desktop verification

## Workspaces and ownership

A Git worktree isolates files and a branch. A Hyprland workspace arranges windows on one Wayland session. Workspaces share keyboard focus, pointer input, audio, and capture. Separate workspaces do not make parallel GUI workers safe.

Use one desktop controller at a time. Other workers can analyze code and tests. Keep T3 Code and the user's existing windows where they are. Apply existing authorization for visible control and recording; a tool session or task folder grants no additional permissions.

Discover live state before choosing a workspace:

```bash
hyprctl version
hyprctl monitors -j
hyprctl workspaces -j
hyprctl clients -j
hyprctl activeworkspace -j
hyprctl activewindow -j
```

Choose a currently unused named workspace such as `tawaq-review-<task-id>`, or the user's designated test workspace. Record original monitor/workspace/focus and the spawned process. Match the new app window to its verified PID and checkout, then retain its Hyprland address. Titles/classes alone can match a live user instance.

For authorized placement, `movetoworkspacesilent` can move the exact window without following it. Confirm syntax against the installed version and read back the workspace afterward. Example with values resolved from live state:

```bash
hyprctl dispatch movetoworkspacesilent "name:$task_workspace,address:$task_address"
```

Switching workspaces changes the visible desktop. Use it for authorized foreground verification. Use the GUI driver's exact-target activation for input; placement itself is not an input route. Restore previous workspace/focus only if the user has not meanwhile selected another one. Close only the process/window owned by this run.

## Interaction and geometry

Use the installed cua-driver skill for native actions, including its current Linux/recording references and advertised runtime capabilities. Prefer fresh semantic targets. If Flutter exposes an incomplete accessibility tree, use verified screenshots and an admitted input route. A dispatch acknowledgement does not prove the app changed.

Hyprland background input is capability-dependent. Inspect route failures; use foreground control within existing authorization. Permission prompts belong to the user. For browser work, prefer T3 preview tools when exposed; they do not replace native Flutter verification.

Monitors can have negative global coordinates, different scales, and rotation. Get current window `at`, `size`, monitor, and workspace. Refresh after moving/resizing or changing layouts. Map image coordinates using actual screenshot dimensions; logical units can differ from pixels.

An off-workspace or occluded app may be absent from compositor region capture. Bring the owned app into an authorized visible test workspace and inspect the result. A cropped desktop image is region evidence, not an attested isolated-window capture.

## Screenshots and video

Inspect tool availability and `--help`. For Omarchy commands or desktop configuration, load the Omarchy skill and capture reference. Routine app verification should use runtime placement rather than machine-wide config changes.

For an unobstructed app, `grim -g "$task_geometry" "$capture_path"` captures a compositor region. Derive geometry from live state and inspect the PNG. Keep size, theme, locale, and text scale consistent for comparisons; include relevant dialogs/popups.

Choose an available recorder supporting the intended scope: installed Omarchy commands, gpu-screen-recorder, wf-recorder, OBS, or the driver's recording route. Presence alone does not prove video works. Capture the affected region/output and identify broader scope in the evidence. For sound tasks, deliberately select desktop/application audio and verify audibility. Include microphone input only when requested.

Recorders are shared resources. Check for an active recorder and retain ownership of the process/session you start. Stop and finalize only your recorder. For cua-driver, keep recording controls and actions on the owning persistent connection and follow its recording reference.

Verify duration, dimensions, and streams with `ffprobe`; decode with FFmpeg and inspect representative frames. Listen to clips proving sound behavior. Save media outside the worktree with revision and flow notes. Verify uploaded PR links.

Done: the flow has visible proof, scope/revision are recorded, desktop context is restored where appropriate, and owned processes/recorders are cleaned up.

Sources: [Hyprland dispatchers](https://wiki.hypr.land/0.54.0/Configuring/Dispatchers/) (consult the installed version's documentation), installed cua-driver Linux/recording guides, and installed Omarchy capture guide.
