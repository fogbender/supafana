import { useMutation } from "@tanstack/react-query";
import classNames from "classnames";
import dayjs from "dayjs";
import relativeTime from "dayjs/plugin/relativeTime";
import React from "react";

import { HiExternalLink as ExternalLink } from "react-icons/hi";
import { SiDungeonsanddragons as DividerGlyph } from "react-icons/si";

import { nbsp } from "./Utils";

import { apiServer, queryClient, queryKeys } from "./client";

import SupafanaLogo from "./landing/assets/logo.svg?url";
import SupabaseLogo from "./landing/assets/supabase-logo-icon.svg?url";

import type { Project as ProjectT } from "../types/supabase";
import type { Grafana as GrafanaT } from "../types/z_types";

dayjs.extend(relativeTime);

const Project = ({ project, grafana }: { project: ProjectT; grafana: GrafanaT | undefined }) => {
  const dividerSize = 32;

  const intervalRef = React.useRef<ReturnType<typeof setTimeout>>();

  React.useEffect(() => {
    if (!grafana) {
      if (
        ["COMING_UP", "GOING_DOWN", "RESTARTING", "UPGRADING", "RESTORING", "PAUSING"].includes(
          project.status
        )
      ) {
        if (!intervalRef.current) {
          intervalRef.current = setInterval(() => {
            queryClient.invalidateQueries({
              queryKey: queryKeys.projects(project.organization_id),
            });
          }, 9000);
        }
      } else {
        clearInterval(intervalRef.current);
        intervalRef.current = undefined;
      }
    }
  }, [project, grafana]);

  return (
    <div className="p-4 m-4 flex gap-4 border border-zinc-500 rounded-lg flex-col lg:flex-row">
      <SupabaseProject project={project} grafana={grafana} />
      {(grafana || project.status.startsWith("ACTIVE")) && (
        <>
          <div className="lg:self-center flex flex-col gap-4 text-base">
            <DividerGlyph size={dividerSize} />
          </div>
          <SupafanaProject project={project} grafana={grafana} />
        </>
      )}
    </div>
  );
};

const SupabaseProject = ({
  project,
  grafana,
}: {
  project: ProjectT;
  grafana: undefined | GrafanaT;
}) => {
  return (
    <div className="text-black dark:text-white bg-dots w-full rounded-2xl">
      <ProjectRow>
        <RowHeader className="basis-1/5 md:basis-1/3">
          <span className="font-bold">Database</span>
        </RowHeader>
        <div>
          <a
            className="inline-flex items-center gap-1.5 font-medium link link-primary dark:link-secondary"
            href={`https://supabase.com/dashboard/project/${project.id}`}
            title={`Open ${project.name} in Supabase`}
            target="_blank"
          >
            <img src={SupabaseLogo} alt="Supabase logo" width={12} height={12} />
            {project.name}
            <ExternalLink size={18} />
          </a>
        </div>
      </ProjectRow>
      <ProjectRow>
        <RowHeader className="basis-1/5 md:basis-1/3">
          <span dangerouslySetInnerHTML={{ __html: nbsp("Project ref") }} />
        </RowHeader>
        <div>
          <span className="font-medium break-all">{project.id}</span>
        </div>
      </ProjectRow>
      <ProjectRow>
        <RowHeader className="basis-1/5 md:basis-1/3">Version</RowHeader>
        <div>
          <span className="font-medium">{project.database?.version}</span>
        </div>
      </ProjectRow>
      <ProjectRow>
        <RowHeader className="basis-1/5 md:basis-1/3">Region</RowHeader>
        <div>
          <span className="font-medium">{project.region}</span>
        </div>
      </ProjectRow>
      <ProjectRow>
        <RowHeader className="basis-1/5 md:basis-1/3">Status</RowHeader>
        <div>
          <span
            className={classNames("flex gap-2 flex-col md:flex-row", "font-medium", {
              "text-success": project.status === "ACTIVE_HEALTHY",
              "text-warning": project.status === "INACTIVE",
              "text-error": project.status !== "ACTIVE_HEALTHY" && project.status !== "INACTIVE",
            })}
          >
            <span>{project.status}</span>
            <span>
              {project.status === "INACTIVE" && !grafana && (
                <span className="text-zinc-500">
                  You’ll have to{" "}
                  <a
                    className="link link-primary dark:link-secondary"
                    href={`https://supabase.com/dashboard/project/${project.id}`}
                  >
                    restore
                  </a>{" "}
                  this project to provision Supafana
                </span>
              )}
            </span>
          </span>
        </div>
      </ProjectRow>
      <ProjectRow>
        <RowHeader className="basis-1/5 md:basis-1/3">Created</RowHeader>
        <div>
          <span className="inline-block font-medium first-letter:capitalize">
            {dayjs(project.created_at).fromNow()}
          </span>
        </div>
      </ProjectRow>
    </div>
  );
};

const SupafanaProject = ({
  project,
  grafana,
}: {
  project: ProjectT;
  grafana: GrafanaT | undefined;
}) => {
  const state = grafana?.state ?? "Ready";
  const plan = grafana?.plan ?? "Trial";
  const created = grafana?.inserted_at ? dayjs(grafana.inserted_at).fromNow() : null;

  const provisionGrafanaMutation = useMutation({
    mutationFn: () => {
      return apiServer.url(`/grafanas/${project.id}`).put().text();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.grafanas(project.organization_id) });
    },
  });

  const upgradeGrafanaMutation = useMutation({
    mutationFn: () => {
      return apiServer
        .url(`/billing/subscriptions/${project.id}`)
        .put()
        .json<{ status: string; url?: string }>();
    },
    onSuccess: res => {
      if (res.status === "redirect" && res.url) {
        window.location.href = res.url;
      } else {
        queryClient.invalidateQueries({ queryKey: queryKeys.grafanas(project.organization_id) });
      }
    },
  });

  const deleteGrafanaMutation = useMutation({
    mutationFn: () => {
      return apiServer.url(`/grafanas/${project.id}`).delete().text();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.grafanas(project.organization_id) });
    },
  });

  const intervalRef = React.useRef<ReturnType<typeof setTimeout>>();

  React.useEffect(() => {
    if (grafana) {
      if (["Provisioning", "Deleting", "Creating", "Starting", "Unknown"].includes(grafana.state)) {
        if (!intervalRef.current) {
          intervalRef.current = setInterval(() => {
            queryClient.invalidateQueries({
              queryKey: queryKeys.grafanas(project.organization_id),
            });
            queryClient.invalidateQueries({
              queryKey: queryKeys.billing(project.organization_id),
            });
          }, 9000);
        }
      } else if (grafana.plan === "Trial") {
        if (!intervalRef.current) {
          intervalRef.current = setInterval(() => {
            queryClient.invalidateQueries({
              queryKey: queryKeys.grafanas(project.organization_id),
            });
          }, 30000);
        }
      } else {
        clearInterval(intervalRef.current);
        intervalRef.current = undefined;
      }
    }
  }, [grafana]);

  const [passwordCopied, setPasswordCopied] = React.useState(false);

  React.useEffect(() => {
    if (passwordCopied) {
      setTimeout(() => {
        setPasswordCopied(false);
      }, 500);
    }
  }, [passwordCopied]);

  const trialEnded =
    (grafana &&
      dayjs(grafana.first_start_at).add(grafana.trial_length_min, "minute").isBefore(dayjs())) ??
    false;

  if (!grafana) {
    if (project.status.startsWith("ACTIVE")) {
      return (
        <div className="flex items-center justify-center bg-dots rounded-xl w-full py-8">
          {provisionGrafanaMutation.isPending || !provisionGrafanaMutation.isIdle ? (
            <span className="loading loading-ring loading-lg text-accent" />
          ) : (
            <button
              onClick={() => {
                provisionGrafanaMutation.mutate();
              }}
              className="btn btn-xs btn-primary text-white"
            >
              Provision Grafana
            </button>
          )}
        </div>
      );
    } else {
      return null;
    }
  }

  return (
    <table className="text-gray-200 dark:text-gray-700 bg-dots table">
      <tbody className="text-black dark:text-white">
        <tr>
          <RowHeader>
            <span className="font-bold">Grafana</span>
          </RowHeader>
          <td colSpan={state === "Running" ? 1 : 2}>
            <a
              className="inline-flex items-center gap-1.5 font-medium link link-primary dark:link-secondary"
              href={`/dashboard/${project.id}/`}
              title={`Open ${project.name} in Supafana`}
              target="_blank"
            >
              <img src={SupafanaLogo} alt="Supabase logo" width={12} height={12} />
              {project.name}
              <ExternalLink size={18} />
            </a>
          </td>
          {state === "Running" && (
            <td>
              <a
                href={`/dashboard/${project.id}/`}
                title={`Open ${project.name} in Supafana`}
                target="_blank"
              >
                <button className="btn btn-xs btn-accent w-20">
                  <span>Open</span>
                </button>
              </a>
            </td>
          )}
        </tr>
        <tr>
          <RowHeader>State</RowHeader>
          <td>
            <span className="font-medium break-all">{state}</span>
          </td>
          {state === "Running" && (
            <td>
              <button
                onClick={() => {
                  if (window.confirm("Are you sure?") === true) {
                    deleteGrafanaMutation.mutate();
                  }
                }}
                className="btn btn-xs btn-warning w-20"
              >
                {deleteGrafanaMutation.isPending ? (
                  <span className="loading loading-ring loading-xs text-black h-3" />
                ) : (
                  <span>Delete</span>
                )}
              </button>
            </td>
          )}
          {(["Failed"].includes(state) ||
            (plan === "Supafana Pro" && ["Deleted"].includes(state))) && (
            <td>
              <button
                onClick={() => {
                  if (!provisionGrafanaMutation.isPending) {
                    provisionGrafanaMutation.mutate();
                  }
                }}
                className="btn btn-xs btn-primary w-20 text-white"
              >
                {provisionGrafanaMutation.isPending ? (
                  <span className="loading loading-ring loading-xs h-3" />
                ) : (
                  <span>Provision</span>
                )}
              </button>
            </td>
          )}
          {plan === "Trial" && trialEnded && state === "Deleted" && (
            <td>
              <span
                className="text-gray-500"
                dangerouslySetInnerHTML={{ __html: nbsp("↓ Upgrade to provision") }}
              />
            </td>
          )}
          {plan === "Trial" && !trialEnded && state === "Deleted" && (
            <td>
              <button
                onClick={() => {
                  provisionGrafanaMutation.mutate();
                }}
                className="btn btn-xs btn-primary w-20 text-white"
              >
                {provisionGrafanaMutation.isPending ? (
                  <span className="loading loading-ring loading-xs h-3" />
                ) : (
                  <span>Provision</span>
                )}
              </button>
            </td>
          )}
        </tr>
        {plan !== "Trial" && (
          <tr>
            <RowHeader>Plan</RowHeader>
            <td>
              <span className="font-medium break-all">{plan}</span>
            </td>
          </tr>
        )}
        {plan === "Trial" && grafana.first_start_at && (
          <tr>
            {trialEnded ? <RowHeader>Trial ended</RowHeader> : <RowHeader>Trial ends</RowHeader>}
            <td>
              <span
                key={grafana.trial_remaining_msec}
                className="inline-block font-medium break-all first-letter:capitalize"
              >
                {dayjs(grafana.first_start_at).add(grafana.trial_length_min, "minute").fromNow()}
              </span>
            </td>
            <td>
              <button
                onClick={() => {
                  upgradeGrafanaMutation.mutate();
                }}
                className="btn btn-xs btn-secondary w-28"
              >
                {upgradeGrafanaMutation.isPending ? (
                  <span className="loading loading-ring loading-xs h-3" />
                ) : (
                  <span dangerouslySetInnerHTML={{ __html: nbsp("Upgrade to Pro") }} />
                )}
              </button>
            </td>
          </tr>
        )}
        {/*
        <tr>
          <RowHeader>Version</RowHeader>
          <td>
            <span className="font-medium">supafana-version</span>
          </td>
        </tr>
        */}
        {created && (
          <tr>
            <RowHeader>Created</RowHeader>
            <td colSpan={2}>
              <span className="inline-block font-medium first-letter:capitalize">{created}</span>
            </td>
          </tr>
        )}
        {grafana.state === "Running" && (
          <tr>
            <RowHeader>User/pass</RowHeader>
            <td>
              <span className="font-medium">
                <code>admin</code>
              </span>
            </td>
            <td>
              <button
                onClick={() => copyTextToClipboard(grafana.password, () => setPasswordCopied(true))}
                className={classNames("btn btn-xs", passwordCopied && "btn-success")}
                dangerouslySetInnerHTML={{ __html: nbsp("Copy password") }}
              />
            </td>
          </tr>
        )}
      </tbody>
    </table>
  );
};

const ProjectRow = ({ children }: { children: JSX.Element[] }) => {
  return (
    <div className="flex flex-col md:flex-row px-4 py-3 border-b border-zinc-500 last-of-type:border-none text-sm">
      {children}
    </div>
  );
};

const RowHeader = ({
  children,
  className,
}: {
  children: JSX.Element | string;
  className?: string;
}) => {
  return (
    <div className={classNames(className)}>
      <span className="text-gray-500 dark:text-gray-300">{children}</span>
    </div>
  );
};

const copyTextToClipboard = (text: string, onSuccess: () => void, onError?: () => void) => {
  navigator.clipboard.writeText(text).then(
    () => {
      onSuccess();
    },
    () => {
      if (onError) {
        onError();
      }
    }
  );
};

export default Project;
