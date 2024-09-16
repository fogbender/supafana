import { useMutation } from "@tanstack/react-query";
import classNames from "classnames";
import dayjs from "dayjs";
import relativeTime from "dayjs/plugin/relativeTime";
import React from "react";

import { HiExternalLink as ExternalLink } from "react-icons/hi";
import { SiDungeonsanddragons as DividerGlyph } from "react-icons/si";

import { apiServer, queryClient, queryKeys } from "./client";

import SupabaseProject from "./SupabaseProject";
import SupafanaProject from "./SupafanaProject";

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

export default Project;
