import React from "react";
import classNames from "classnames";
import dayjs from "dayjs";
import relativeTime from "dayjs/plugin/relativeTime";
import { useQuery, useMutation } from "@tanstack/react-query";

import { HiExternalLink as ExternalLink } from "react-icons/hi";
import { SiDungeonsanddragons as DividerGlyph } from "react-icons/si";

import { apiServer, queryClient, queryKeys } from "./client";

import SupabaseLogo from "./landing/assets/supabase-logo-icon.svg?url";
import SupafanaLogo from "./landing/assets/logo.svg?url";

import type { Project as ProjectT } from "../types/supabase";
import type { Grafana as GrafanaT } from "../types/z_types";

dayjs.extend(relativeTime);

const Project = ({ project, grafana }: { project: ProjectT; grafana: GrafanaT | undefined }) => {
  const dividerSize = 32;

  return (
    <div className="p-4 m-4 flex gap-4 border rounded-lg flex-col md:flex-row">
      <SupabaseProject project={project} />
      {(!grafana || ["ACTIVE_HEALTHY", "ACTIVE_UNHEALTHY"].includes(project.status)) && (
        <>
          <div className="self-center flex flex-col gap-4 text-base">
            <DividerGlyph size={dividerSize} />
          </div>
          <SupafanaProject project={project} grafana={grafana} />
        </>
      )}
    </div>
  );
};

const SupabaseProject = ({ project }: { project: ProjectT }) => {
  return (
    <table className="text-gray-200 dark:text-gray-700 bg-dots table">
      <tbody className="text-black dark:text-white">
        <tr>
          <RowHeader>
            <span className="font-bold">Database</span>
          </RowHeader>
          <td>
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
          </td>
        </tr>
        <tr>
          <RowHeader>Project&nbsp;ref</RowHeader>
          <td>
            <span className="font-medium break-all">{project.id}</span>
          </td>
        </tr>
        <tr>
          <RowHeader>Version</RowHeader>
          <td>
            <span className="font-medium">{project.database?.version}</span>
          </td>
        </tr>
        <tr>
          <RowHeader>Region</RowHeader>
          <td>
            <span className="font-medium">{project.region}</span>
          </td>
        </tr>
        <tr>
          <RowHeader>Status</RowHeader>
          <td>
            <span
              className={classNames(
                "font-medium",
                (() => {
                  if (project.status === "ACTIVE_HEALTHY") {
                    return "text-success";
                  } else if (project.status === "INACTIVE") {
                    return "text-warning";
                  } else {
                    return "text-error";
                  }
                })()
              )}
            >
              {project.status}
            </span>
          </td>
        </tr>
        <tr>
          <RowHeader>Created</RowHeader>
          <td>
            <span className="inline-block font-medium first-letter:capitalize">
              {dayjs(project.created_at).fromNow()}
            </span>
          </td>
        </tr>
      </tbody>
    </table>
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
  const plan = grafana?.plan ?? "Hobby";
  const created = grafana?.inserted_at ? dayjs(grafana.inserted_at).fromNow() : null;

  const provisionGrafanaMutation = useMutation({
    mutationFn: () => {
      return apiServer.url(`/grafanas/${project.id}`).put().text();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.grafanas(project.organization_id) });
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
          }, 9000);
        }
      } else {
        clearInterval(intervalRef.current);
        intervalRef.current = undefined;
      }
    }
  }, [grafana]);

  if (!grafana) {
    return (
      <div className="flex items-center justify-center bg-dots rounded-xl w-full md:w-64 py-8 md:py-0">
        {provisionGrafanaMutation.isPending || !provisionGrafanaMutation.isIdle ? (
          <span className="loading loading-ring loading-lg text-accent" />
        ) : (
          <button
            onClick={() => {
              provisionGrafanaMutation.mutate();
            }}
            className="btn btn-xs btn-error"
          >
            Provision Grafana
          </button>
        )}
      </div>
    );
  }

  const [passwordCopied, setPasswordCopied] = React.useState(false);

  React.useEffect(() => {
    if (passwordCopied) {
      setTimeout(() => {
        setPasswordCopied(false);
      }, 500);
    }
  }, [passwordCopied]);

  return (
    <table className="text-gray-200 dark:text-gray-700 bg-dots table">
      <tbody className="text-black dark:text-white">
        <tr>
          <RowHeader>
            <span className="font-bold">Grafana</span>
          </RowHeader>
          <td>
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
                className="btn btn-xs btn-info w-20"
              >
                {deleteGrafanaMutation.isPending ? (
                  <span className="loading loading-ring loading-xs text-black h-3" />
                ) : (
                  <span>Delete</span>
                )}
              </button>
            </td>
          )}
          {["Failed", "Deleted"].includes(state) && (
            <td>
              <button
                onClick={() => {
                  provisionGrafanaMutation.mutate();
                }}
                className="btn btn-xs btn-info w-20"
              >
                {provisionGrafanaMutation.isPending ? (
                  <span className="loading loading-ring loading-xs text-black h-3" />
                ) : (
                  <span>Provision</span>
                )}
              </button>
            </td>
          )}
        </tr>
        <tr>
          <RowHeader>Plan</RowHeader>
          <td>
            <span className="font-medium break-all">{plan}</span>
          </td>
        </tr>
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
            <td>
              <span className="inline-block font-medium first-letter:capitalize">{created}</span>
            </td>
          </tr>
        )}
        <tr>
          <RowHeader>User/password</RowHeader>
          <td>
            <span className="font-medium">
              <code>admin</code>
            </span>
          </td>
          <td>
            <button
              onClick={() => copyTextToClipboard(grafana.password, () => setPasswordCopied(true))}
              className={classNames("btn btn-xs", passwordCopied && "btn-success")}
            >
              Copy&nbsp;password
            </button>
          </td>
        </tr>
      </tbody>
    </table>
  );
};

const RowHeader = ({ children }: { children: JSX.Element | string }) => {
  return (
    <td>
      <span className="text-gray-500 dark:text-gray-300">{children}</span>
    </td>
  );
};

const copyTextToClipboard = (text: string, onSuccess: () => void, onError?: () => void) => {
  navigator.clipboard.writeText(text).then(
    () => {
      onSuccess();
    },
    err => {
      if (onError) {
        onError();
      }
    }
  );
};

export default Project;
