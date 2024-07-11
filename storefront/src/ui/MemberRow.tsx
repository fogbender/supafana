import classNames from "classnames";
import React from "react";
import { useMutation } from "@tanstack/react-query";

import { apiServer, queryClient, queryKeys } from "./client";

import type { Member } from "../types/supabase";

const MemberRow = ({ m, verifyText }: { m: Member; verifyText: string }) => {
  const [email, setEmail] = React.useState(m.user_name.includes("@") ? m.user_name : "");
  const [isConfirmed, setIsConfirmed] = React.useState(false);
  const [badEmail, setBadEmail] = React.useState(false);
  const [verificationCode, setVerificationCode] = React.useState("");

  const sendVerificationCodeMutation = useMutation({
    mutationFn: () => apiServer.url("/send-email-verification-code").post({ email }).text(),
    onError: error => {
      if (error.message === "Invalid email address") {
        setBadEmail(true);
      }
    },
  });

  const probeVerificationCodeMutation = useMutation({
    mutationFn: () =>
      apiServer
        .url("/probe-email-verification-code")
        .post({ verificationCode, userId: m.user_id })
        .text(),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.me() });
      setIsConfirmed(true);
    },
  });

  return (
    <tr>
      <td>
        <span className="text-gray-700 dark:text-gray-300 font-medium">{m.user_name}</span>
      </td>
      <td>
        <span className="text-gray-700 dark:text-gray-300">
          {(() => {
            if (isConfirmed) {
              return email;
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
                          "border-gray-500"
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
          })()}
        </span>
      </td>
      <td className="text-black dark:text-white">
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
      </td>
    </tr>
  );
};

export default MemberRow;
