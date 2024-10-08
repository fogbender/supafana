import classNames from "classnames";
import React from "react";
import { useMutation } from "@tanstack/react-query";

import { apiServer, queryClient, queryKeys } from "./client";

import type { Member } from "../types/supabase";

const MemberRow = ({
  m,
  me,
  verifyText,
  children,
}: {
  m: Member;
  me: null | Member;
  verifyText: string;
  children?: JSX.Element;
}) => {
  const [email, setEmail] = React.useState(
    (() => {
      if (!m.email) {
        if (m.user_name.includes("@")) {
          return m.user_name;
        } else {
          return "";
        }
      } else {
        return m.email;
      }
    })()
  );
  const [isConfirmed, setIsConfirmed] = React.useState(false);
  const [badEmail, setBadEmail] = React.useState(false);
  const [verificationCode, setVerificationCode] = React.useState("");
  const [verifyingUserId, setVerifyingUserId] = React.useState<string>();
  const [codeProbeError, setCodeProbeError] = React.useState(false);

  // XXX Don't show confirmation input when 'me' already there (i.e. logged in)

  const sendVerificationCodeMutation = useMutation({
    mutationFn: () => {
      setVerifyingUserId(m.user_id);
      return apiServer.url("/send-email-verification-code").post({ email }).text();
    },
    onError: error => {
      if (error.message === "Invalid email address") {
        setBadEmail(true);
      }
    },
  });

  const probeVerificationCodeMutation = useMutation({
    mutationFn: () => {
      return apiServer
        .url("/probe-email-verification-code")
        .post({ verificationCode, userId: m.user_id })
        .text();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.me() });
      setIsConfirmed(true);
    },
    onError: () => {
      setCodeProbeError(true);
    },
  });

  const myself = me?.user_id === m.user_id;

  const emailElement = (() => {
    if (isConfirmed && myself) {
      return email;
    } else if (me || (m.email && !isConfirmed && verifyingUserId !== m.user_id)) {
      return m.email;
    } else {
      return (
        <div className="flex flex-col gap-1.5">
          <input
            type="email"
            value={email}
            onChange={e => {
              setBadEmail(false);
              setEmail(e.target.value);
            }}
            className={classNames(
              "bg-white dark:bg-gray-600",
              "border rounded px-2 py-1",
              badEmail ? "border-red-500" : "border-gray-500"
            )}
            placeholder="Enter your email"
          />
          {sendVerificationCodeMutation.isSuccess && (
            <div className="flex items-center gap-1.5">
              <input
                onKeyUp={e => {
                  if (e.key === "Enter") {
                    probeVerificationCodeMutation.mutate();
                  }
                }}
                type="text"
                value={verificationCode}
                disabled={probeVerificationCodeMutation.isPending}
                onChange={e => {
                  setVerificationCode(e.target.value);
                }}
                className={classNames(
                  "bg-white dark:bg-gray-600",
                  "border rounded px-2 py-1",
                  codeProbeError ? "border border-error" : "border-gray-500"
                )}
                placeholder="Enter verification code"
              />
              <button
                type="button"
                disabled={verificationCode === ""}
                className="btn btn-xs btn-accent disabled:text-zinc-500 text-black dark:text-white"
                onClick={() => probeVerificationCodeMutation.mutate()}
              >
                Go
              </button>
            </div>
          )}
        </div>
      );
    }
  })();

  return (
    <div className="flex flex-col md:flex-row border-b border-zinc-500 last-of-type:border-none">
      <div className="flex flex-col px-4 py-3 md:basis-1/3">
        <span className="text-gray-700 dark:text-gray-300 font-medium break-all">
          {m.user_name}
        </span>
        <span className="flex gap-1.5 items-center">
          <span className="text-gray-700 dark:text-gray-300 text-xs font-light">{m.role_name}</span>
          {myself && (
            <span className="text-white px-1 rounded-full text-[9px] font-bold bg-success">
              You!
            </span>
          )}
        </span>
      </div>
      <div className="text-gray-700 dark:text-gray-300 break-all px-4 py-3 items-center md:basis-1/3">
        {emailElement}
      </div>
      <div className="text-black dark:text-white px-4 py-3 items-center ">
        {me ? (
          children || null
        ) : (
          <button
            className="btn btn-accent btn-xs w-28"
            disabled={!m.email && email === ""}
            onClick={() => {
              setVerificationCode("");
              sendVerificationCodeMutation.mutate();
            }}
          >
            {sendVerificationCodeMutation.isPending ? (
              <span className="text-black loading loading-ring loading-xs h-3"></span>
            ) : (
              <span className="leading-none">
                {sendVerificationCodeMutation.isSuccess ? (
                  <span>Send new code</span>
                ) : (
                  <span>{verifyText}</span>
                )}
              </span>
            )}
          </button>
        )}
      </div>
    </div>
  );
};

export default MemberRow;
