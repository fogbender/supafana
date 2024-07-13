import classNames from "classnames";
import React from "react";
import { useMutation } from "@tanstack/react-query";

import { apiServer, queryClient, queryKeys } from "./client";

import type { Member } from "../types/supabase";
import type { Me } from "../types/supafana";

const MemberRow = ({
  m,
  me,
  verifyText,
  children,
}: {
  m: Member;
  me: null | Me;
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
        return "";
      }
    })()
  );
  const [isConfirmed, setIsConfirmed] = React.useState(false);
  const [badEmail, setBadEmail] = React.useState(false);
  const [verificationCode, setVerificationCode] = React.useState("");
  const [verifyingUserId, setVerifyingUserId] = React.useState<string>();
  const [codeProbeError, setCodeProbeError] = React.useState(false);

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
    } else if (m.email && !isConfirmed && verifyingUserId !== m.user_id) {
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
                className="btn btn-xs btn-accent"
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

  console.log(emailElement);

  return (
    <tr>
      <td>
        <div className="flex flex-col">
          <span className="text-gray-700 dark:text-gray-300 font-medium">{m.user_name}</span>
          <span className="flex gap-1.5 items-center">
            <span className="text-gray-700 dark:text-gray-300 text-xs font-light">
              {m.role_name}
            </span>
            {myself && (
              <span className="text-white px-1 rounded-full text-[9px] font-bold bg-success">
                You!
              </span>
            )}
          </span>
        </div>
      </td>
      <td>
        <span className="text-gray-700 dark:text-gray-300">{emailElement}</span>
      </td>
      <td className="text-black dark:text-white">
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
      </td>
    </tr>
  );
};

export default MemberRow;
