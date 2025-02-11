defmodule Tasker.Accounts.WorkerNotifier do
  import Swoosh.Email

  alias Tasker.Mailer

  # Delivers the email using the application mailer.
  defp deliver(recipient, subject, body) do
    email =
      new()
      |> to(recipient)
      |> from({"Tasker", "contact@example.com"})
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  @doc """
  Deliver instructions to confirm account.
  """
  def deliver_confirmation_instructions(worker, url) do
    deliver(worker.email, "Confirmation instructions", """

    ==============================

    Hi #{worker.email},

    You can confirm your account by visiting the URL below:

    #{url}

    If you didn't create an account with us, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to reset a worker password.
  """
  def deliver_reset_password_instructions(worker, url) do
    deliver(worker.email, "Reset password instructions", """

    ==============================

    Hi #{worker.email},

    You can reset your password by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to update a worker email.
  """
  def deliver_update_email_instructions(worker, url) do
    deliver(worker.email, "Update email instructions", """

    ==============================

    Hi #{worker.email},

    You can change your email by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end
end
